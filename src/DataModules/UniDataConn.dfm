object dmConn: TdmConn
  OnCreate = DataModuleCreate
  Height = 299
  Width = 506
  PixelsPerInch = 120
  object conUni: TUniConnection
    Options.DefaultSortType = stCaseInsensitive
    DefaultTransaction.DefaultCloseAction = taCommit
    LoginPrompt = False
    AfterConnect = conUniAfterConnect
    BeforeConnect = connBeforeConnect
    OnError = conUniError
    Left = 270
    Top = 150
  end
  object UniSQLMonitor1: TUniSQLMonitor
    Active = False
    Options = [moDialog, moSQLMonitor, moDBMonitor, moCustom, moHandled]
    DBMonitorOptions.Host = '0'
    DBMonitorOptions.Port = 0
    DBMonitorOptions.ReconnectTimeout = 0
    DBMonitorOptions.SendTimeout = 0
    TraceFlags = [tfQPrepare, tfQExecute, tfQFetch, tfError, tfStmt, tfConnect, tfTransact, tfBlob, tfService, tfMisc, tfParams, tfObjDestroy, tfPool]
    OnSQL = UniSQLMonitor1SQL
    Left = 370
    Top = 149
  end
end
