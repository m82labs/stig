$RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, 25)
$RunspacePool.Open()


$Setup_Query = @"
CREATE DATABASE SqltopTest;
GO

USE SqltopTest;
Go

CREATE SCHEMA OnDisk AUTHORIZATION dbo;
GO

CREATE TABLE OnDisk.VehicleLocations
(
  VehicleLocationID bigint IDENTITY(1,1),
  RegistrationNumber nvarchar(20) NOT NULL,
  TrackedWhen datetime2(2) NOT NULL,
  Longitude decimal(18,4) NOT NULL,
  Latitude decimal(18,4) NOT NULL,
  CONSTRAINT PK_VehicleLocations PRIMARY KEY CLUSTERED (
      VehicleLocationID
 )
);
GO

CREATE PROCEDURE OnDisk.InsertVehicleLocation
 @RegistrationNumber nvarchar(20),
 @TrackedWhen datetime2(2),
 @Longitude decimal(18,4),
 @Latitude decimal(18,4)
 WITH EXECUTE AS OWNER
 AS
 BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  INSERT OnDisk.VehicleLocations
   (RegistrationNumber, TrackedWhen, Longitude, Latitude)
  VALUES
   (@RegistrationNumber, @TrackedWhen, @Longitude, @Latitude);
  RETURN 0;
 END;
 GO

CREATE PROCEDURE OnDisk.UpdateVehicleLocation
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;

 UPDATE TOP(1)
 SET TrackedWhen = GETDATE()
 FROM OnDisk.VehicleLocations
 ORDER BY (SELECT NEWID());
END;
GO
"@

Invoke-Sqlcmd -ServerInstance localhost -Username sa -Password 1ontsurt! -Database master -Query $Setup_Query

$ScriptBlock = {
    $Applications = @(
        'Some UI App',
        'Mark is Awesome',
        'Warehouse Nonsense',
        'Entity Framework Trash'
    )

    $Hosts = @(
        'APPSRV',
        'WEBSRV',
        'REPORT'
    )

    $Query = @"
    DECLARE @RegistrationNumber nvarchar(20);
    DECLARE @TrackedWhen datetime2(2);
    DECLARE @Longitude decimal(18,4);
    DECLARE @Latitude decimal(18,4);

    DECLARE @Counter int = 0;
    SET NOCOUNT ON;

    WHILE @Counter < 500000
    BEGIN
     -- create some dummy data
     SET @RegistrationNumber = N'EA' + RIGHT(N'00' + CAST(@Counter % 100 AS nvarchar(10)), 3) + N'-GL';
     SET @TrackedWhen = SYSDATETIME();
     SET @Longitude = RAND() * 100;
     SET @Latitude = RAND() * 100;

     EXEC OnDisk.UpdateVehicleLocation
     -- @RegistrationNumber, @TrackedWhen, @Longitude, @Latitude;

     SET @Counter += 1;
    END;
"@

    Invoke-Sqlcmd  -ServerInstance localhost `
                   -Database SqltopTest `
                   -Username sa `
                   -Password "1ontsurt!" `
                   -HostName "PROD-$($Hosts[$(Get-Random -Minimum 0 -Maximum 2)])-$(Get-Random -Maximum 99 -Minimum 10)" `
                   -Query $Query `
                   -ApplicationName "$($Applications[$(Get-Random -Minimum 0 -Maximum 3)])"

}

$Runspaces = @()
(1..100) | ForEach-Object {
    $Runspace = [powershell]::Create().AddScript($ScriptBlock)
    $Runspace.RunspacePool = $RunspacePool
    $Runspaces += New-Object PSObject -Property @{
        Runspace = $Runspace
        State = $Runspace.BeginInvoke()
    }
}

while ( $Runspaces.State.IsCompleted -contains $False) { Start-Sleep -Milliseconds 10 }

$Results = @()

$Runspaces | ForEach-Object {
    $Results += $_.Runspace.EndInvoke($_.State)
}

$RunspacePool.Close()

$Teardown_Query = "DROP DATABASE SqltopTest;"
Invoke-Sqlcmd -ServerInstance localhost -Username sa -Password 1ontsurt! -Database master -Query $Teardown_Query
