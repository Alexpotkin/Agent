#$ComponentName = "frontol"
function global:frontol {
    # function frontol analizator
    param($ini)
    $ModulName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)
    # Получаем текущую дату и время
    $currentDate = Get-Date  
    [int]$IDGROUP = $ini.frontol.ID_GROUP
    if (-not $IDGROUP -or $IDGROUP -eq 0) {
        return  $ModulName + "ID_GROUP пустая или равна 0."
    }
    # База данных 
    $dbServerName = $ini.frontol.dbServerName
    $dbUser = $ini.frontol.dbUser
    $dbPass = $ini.frontol.dbPass
    # Проверка на существование  переменных
    if ([string]::IsNullOrWhiteSpace($dbServerName) -or 
        [string]::IsNullOrWhiteSpace($dbUser) -or 
        [string]::IsNullOrWhiteSpace($dbPass)) {
        Debuging -param_debug $debug -debugmessage ("DB Error " + $ModulName + " | Не заполнены параметры подключения к серверу!" ) -typemessage error
        return
    }
    [string]$szConnect = "Driver={Firebird/InterBase(r) driver};Dbname=$dbServerName;Pwd=$dbPass;CHARSET=WIN1251;UID=$dbUser" 
    $cnDB = New-Object System.Data.Odbc.OdbcConnection($szConnect)
    $dsDB = New-Object System.Data.DataSet
    try {
        $cnDB.Open() 
        $adDB = New-Object System.Data.Odbc.OdbcDataAdapter 
        $adDB.SelectCommand = New-Object System.Data.Odbc.OdbcCommand("SELECT  S.NAME || ' ' ||
        COALESCE(A1.NAME || ': ' || AV1.NAME || ' ', '') ||
        COALESCE(A2.NAME || ': ' || AV2.NAME || ' ', '') ||
        COALESCE(A3.NAME || ': ' || AV3.NAME || ' ', '') ||
        COALESCE(A4.NAME || ': ' || AV4.NAME || ' ', '') ||
        COALESCE(A5.NAME || ': ' || AV5.NAME || ' ', '')
      AS SNAME,
      WareCode, WareMark,
      sum(T.SummWD) as SummWD,
      sum(T.Summ) as Summ,
      SUM(Quantity) AS Quantity
FROM DOCUMENT D LEFT JOIN TRANZT T ON
               D.ID = T.DOCUMENTID
              LEFT JOIN SPRT S ON
               S.CODE = T.WareCode
              LEFT JOIN ASPSCHM ASH ON ASH.CODE = T.ASPECTSCHEME
              LEFT JOIN ASPECT A1 ON A1.ASPECTSCHEMEID = ASH.ID AND A1.CODE = 1
              LEFT JOIN ASPECT A2 ON A2.ASPECTSCHEMEID = ASH.ID AND A2.CODE = 2
              LEFT JOIN ASPECT A3 ON A3.ASPECTSCHEMEID = ASH.ID AND A3.CODE = 3
              LEFT JOIN ASPECT A4 ON A4.ASPECTSCHEMEID = ASH.ID AND A4.CODE = 4
              LEFT JOIN ASPECT A5 ON A5.ASPECTSCHEMEID = ASH.ID AND A5.CODE = 5
              LEFT JOIN ASPVALUE AV1 ON AV1.CODE = T.ASPECTVALUE1 AND AV1.ASPECTID = A1.ID
              LEFT JOIN ASPVALUE AV2 ON AV2.CODE = T.ASPECTVALUE2 AND AV2.ASPECTID = A2.ID
              LEFT JOIN ASPVALUE AV3 ON AV3.CODE = T.ASPECTVALUE3 AND AV3.ASPECTID = A3.ID
              LEFT JOIN ASPVALUE AV4 ON AV4.CODE = T.ASPECTVALUE4 AND AV4.ASPECTID = A4.ID
              LEFT JOIN ASPVALUE AV5 ON AV5.CODE = T.ASPECTVALUE5 AND AV5.ASPECTID = A5.ID
WHERE

    D.STATE = 1 and (D.ISFISCAL = 1) AND (D.ChequeType in (0, 1, 2)) AND                                 
    T.TranzType IN (1,2,11,12)
    AND S.PARENTID = (SELECT ID FROM SPRT WHERE CODE = ?)
    AND T.TRANZDATE = ?
GROUP BY
    WareCode, WareMark,
    S.NAME || ' ' ||
        COALESCE(A1.NAME || ': ' || AV1.NAME || ' ', '') ||
        COALESCE(A2.NAME || ': ' || AV2.NAME || ' ', '') ||
        COALESCE(A3.NAME || ': ' || AV3.NAME || ' ', '') ||
        COALESCE(A4.NAME || ': ' || AV4.NAME || ' ', '') ||
        COALESCE(A5.NAME || ': ' || AV5.NAME || ' ', '') 
ORDER BY
    WareCode, SNAME", $cnDB)
        $adDB.SelectCommand.Parameters.Add((New-Object Data.Odbc.OdbcParameter("?", $IDGROUP))) | Out-Null
        $adDB.SelectCommand.Parameters.Add((New-Object Data.Odbc.OdbcParameter("?", $currentDate))) | Out-Null
        $adDB.Fill($dsDB)     | Out-Null     
        $cnDB.Close() 
    }
    catch [System.Data.Odbc.OdbcException] {
        $_.Exception
        $_.Exception.Message
        $_.Exception.ItemName
        Debuging -param_debug $debug -debugmessage ("CATCH: " + $ModulName + " | Error!" ) -typemessage error
        return
    }
    $totalQuantity = 0  
    foreach ($row in $dsDB[0].Tables[0].Rows ) {
        $quantity = $row['Quantity'] 
        $totalQuantity += $quantity 
    } 
    return  "MOD: " + $ModulName + " | " + "Количество продаж: $totalQuantity"
}