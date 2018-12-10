JobClass.define('rebuild-drop') {
  parameters {|params|
    params.add SQLFileParam.new
    params.add DestTableParam.new
    params.add SrcTableParam.new
    params.add SQLFileParam.new('table-def', 'PATH', 'Create table file.')
    params.add OptionalBoolParam.new('analyze', 'ANALYZE table after SQL is executed.', default: true)
    params.add OptionalBoolParam.new('vacuum', 'VACUUM table after SQL is executed.')
    params.add OptionalBoolParam.new('vacuum-sort', 'VACUUM SORT table after SQL is executed.')
    params.add KeyValuePairsParam.new('grant', 'KEY:VALUE', 'GRANT table after SQL is executed. (required keys: privilege, to)')
    params.add DataSourceParam.new('sql')
  }

  parameters_filter {|job|
    job.provide_sql_file_by_job_id
  }

  declarations {|params|
    params['sql-file'].declarations
  }

  script {|params, script|
    script.task(params['data-source']) {|task|
      task.transaction {
        # CREATE
        task.drop_force '$dest_table'
        task.exec params['table-def']

        # INSERT
        task.exec params['sql-file']

        # GRANT
        task.grant_if params['grant'], '$dest_table'
      }

      # VACUUM, ANALYZE
      task.vacuum_if params['vacuum'], params['vacuum-sort'], '$dest_table'
      task.analyze_if params['analyze'], '$dest_table'
    }
  }
}
