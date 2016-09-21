#If RUN_UNDER_VISUALSTUDIO Then
' Indicates if this Visual Basic Script will be executed under DVT.
#Const DVT_INTERPRETS_SCRIPT = False
#Else
#Const DVT_INTERPRETS_SCRIPT = True
#End If

#If DVT_INTERPRETS_SCRIPT Then
#include "Includes.vbc"
#End If

'Test tool class, this class runs IHE-RO scenario's and generates results files
Class UPSCreate
    Inherits TestToolUPS_CLIENT_SERVER

    Public Sub New()
        MyBase.New(DVTKActor.TMS, UPS_Scenario.UpsCreate)
    End Sub

    Public Overrides Function GetScenarioToRun() As Scenario
        Return New SendUPSCreate(TestToolConfiguration.GetInstance().GetScriptPath() + "..\..\Datasets\CLIENTSERVER\UPSMessages\N-CREATE-REQ.dcm")
    End Function

End Class

Class UPSWorklistQuery
    Inherits TestToolUPS_CLIENT_SERVER

    Public Sub New()
        MyBase.New(DVTKActor.TMS, UPS_Scenario.UpsCreate)
    End Sub

    Public Overrides Function GetScenarioToRun() As Scenario
        Return New SendUPSWorklistQuery(TestToolConfiguration.GetInstance().GetScriptPath() + "..\..\Datasets\CLIENTSERVER\UPSMessages\C-FIND-RQ.dcm")
    End Function

End Class

Class UPSInProgess
    Inherits TestToolUPS_CLIENT_SERVER

    Public Sub New()
        MyBase.New(DVTKActor.TMS, UPS_Scenario.UpsInProgress)
    End Sub

    Public Overrides Function GetScenarioToRun() As Scenario
        Return New SendUPSInProgress(true)
    End Function

End Class

Class UPSProgressUpdate
    Inherits TestToolUPS_CLIENT_SERVER

    Public Sub New()
        MyBase.New(DVTKActor.TMS, UPS_Scenario.UpsProgressUpdate)
    End Sub

    Public Overrides Function GetScenarioToRun() As Scenario
        Return New SendUPSProgressUpdate(TestToolConfiguration.GetInstance().GetScriptPath() + "..\..\Datasets\CLIENTSERVER\UPSMessages\N-SET-RQ[RO26].dcm")
    End Function

End Class

Class UPSFinalUpdate
    Inherits TestToolUPS_CLIENT_SERVER

    Public Sub New()
        MyBase.New(DVTKActor.TMS, UPS_Scenario.UpsFinalUpdate)
    End Sub

    Public Overrides Function GetScenarioToRun() As Scenario
        Return New SendUPSFinalUpdate(TestToolConfiguration.GetInstance().GetScriptPath() + "..\..\Datasets\CLIENTSERVER\UPSMessages\N-SET-RQ[RO21].dcm")
    End Function

End Class

Class UPSCompletedOrCancelled
    Inherits TestToolUPS_CLIENT_SERVER

    Public Sub New()
        MyBase.New(DVTKActor.TMS, UPS_Scenario.UpsCompletedOrCanceled)
    End Sub

    Public Overrides Function GetScenarioToRun() As Scenario
        Return New SendUPSCompletedOrCanceled("true")
    End Function

End Class

Class Example1 
    Inherits TestToolBase

    Public Sub New()
        MyBase.New()
    End Sub

    Protected Overrides Sub Execute()
    End Sub
        
End Class

'Implementation of the main function of DVTk scripts
Module DvtkScript

    ' Entry point of this Visual Basic Script.
    Sub Main(ByVal CmdArgs() As String)

    Dim selectedAutomaticTestingConfiguration As System.Xml.XmlDocument = New System.Xml.XmlDocument

    TesttoolRunner.RunTool(new Example1(), TesttoolRunner.TestSessionFileName_UPS_CLIENT)

    Try
        selectedAutomaticTestingConfiguration.Load(TestToolConfiguration.GetInstance().GetScriptPath() + ReferenceDataSet.GetInstance().getCurrentAutomaticTestXMLFileName)
    Catch ex As Exception
        selectedAutomaticTestingConfiguration = Nothing
        Reporter.GetInstance().ReportErrorMessage("XML node CurrentAutomaticTestName in the <Instalation dir>\Sessionfiles\Scripts\CurrentAutomaticTestingConfiguration.xml doesn't have a correct value")
    End Try

    If Not (selectedAutomaticTestingConfiguration Is Nothing)

        TesttoolRunner.RunTool(New UPSCreate(), TesttoolRunner.TestSessionFileName_UPS_CLIENT)
        TesttoolRunner.RunTool(New UPSInProgess(), TesttoolRunner.TestSessionFileName_UPS_CLIENT)
        TesttoolRunner.RunTool(New UPSProgressUpdate(), TesttoolRunner.TestSessionFileName_UPS_CLIENT)
        TesttoolRunner.RunTool(New UPSFinalUpdate(), TesttoolRunner.TestSessionFileName_UPS_CLIENT)
        TesttoolRunner.RunTool(New UPSCompletedOrCancelled(), TesttoolRunner.TestSessionFileName_UPS_CLIENT)
    End if

    End Sub

End Module