CodeCoverage\TestCoverageApplication\packages\OpenCover.4.6.166\tools\OpenCover.Console.exe "-target:c:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe" -targetargs:".\CodeCoverage\TestCoverageApplication\TestCoverageApplication.Tests\bin\Debug\TestCoverageApplication.Tests.dll /TestAdapterPath:SpecFlowTests\bin\Debug\ /EnableCodeCoverage /InIsolation /Logger:trx" -register:user -output:\\Nsdbuildsrv-vrt\cdb_mssql_trace\sharp-test.xml -excludebyfile:*.Designer.cs -filter:"+[TestCoverageApplication*]* -[TestCoverageApplication.Tests*]*