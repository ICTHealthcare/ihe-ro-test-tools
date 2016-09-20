#If RUN_UNDER_VISUALSTUDIO Then
' Indicates if this Visual Basic Script will be executed under DVT.
#Const DVT_INTERPRETS_SCRIPT = False
#Else
#Const DVT_INTERPRETS_SCRIPT = True
#End If

#If DVT_INTERPRETS_SCRIPT Then
#include "Includes.vbc"
#End If

Class UPSCreate
    Inherits TestToolUPS_CLIENT_SERVER
    private nCreatePath As String

    Public Sub New(Byval path as String)
        MyBase.New(DVTKActor.TMS, UPS_Scenario.UpsCreate)
        nCreatePath = path
    End Sub

    Public Overrides Function GetScenarioToRun() As Scenario
        Return New SendUPSCreate(nCreatePath)
    End Function

End Class

Class UPSWorklistQuery
    Inherits TestToolUPS_CLIENT_SERVER
    private cFindPath As String

    Public Sub New(Byval path as String)
        MyBase.New(DVTKActor.TMS, UPS_Scenario.WorklistQuery)
        cFindPath = path

    End Sub

    Public Overrides Function GetScenarioToRun() As Scenario
        Return New SendUPSWorklistQuery(cFindPath)
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
    private nSet As String

    Public Sub New(Byval path as String)
        MyBase.New(DVTKActor.TMS, UPS_Scenario.UpsProgressUpdate)
        nSet = path
    End Sub

    Public Overrides Function GetScenarioToRun() As Scenario
        Return New SendUPSProgressUpdate(nSet)
    End Function

End Class

Class UPSFinalUpdate
    Inherits TestToolUPS_CLIENT_SERVER
    private nSet As String

    Public Sub New(Byval path as String)
        MyBase.New(DVTKActor.TMS, UPS_Scenario.UpsFinalUpdate)
        nSet = path
    End Sub

    Public Overrides Function GetScenarioToRun() As Scenario
        Return New SendUPSFinalUpdate(nSet)
    End Function

End Class

Class UPSCompletedOrCancelled
    Inherits TestToolUPS_CLIENT_SERVER
    Dim isCompleted As String

    Public Sub New(ByVal completed As String)
        MyBase.New(DVTKActor.TMS, UPS_Scenario.UpsCompletedOrCanceled)
        isCompleted = completed 
    End Sub

    Public Overrides Function GetScenarioToRun() As Scenario
        Return New SendUPSCompletedOrCanceled(isCompleted)
    End Function

End Class

Class Example1
    Inherits TestToolBase

    Protected Overrides Sub Execute()

    End Sub

End Class

'Implementation of the main function of DVTk scripts
Module DvtkScript

    ' Entry point of this Visual Basic Script.
    Sub Main(ByVal CmdArgs() As String)

    TesttoolRunner.RunTool(New Example1(), TesttoolRunner.TestSessionFileName_RTA)

    Dim selectedAutomaticTestingConfiguration As System.Xml.XmlDocument = New System.Xml.XmlDocument

    Try
        selectedAutomaticTestingConfiguration.Load(TestToolConfiguration.GetInstance().GetScriptPath() + ReferenceDataSet.GetInstance().getCurrentAutomaticTestXMLFileName)
    Catch ex As Exception
        selectedAutomaticTestingConfiguration = Nothing
        Reporter.GetInstance().ReportErrorMessage("XML node CurrentAutomaticTestName in the <Instalation dir>\Sessionfiles\Scripts\CurrentAutomaticTestingConfiguration.xml doesn't have a correct value")
    End Try

    If Not (selectedAutomaticTestingConfiguration Is Nothing)

        Dim scenarioNode As System.Xml.XmlNode

        For Each scenarioNode In selectedAutomaticTestingConfiguration.DocumentElement.SelectNodes("Scenario")

            Select Case scenarioNode.Attributes("Name").Value()
                Case "SendUPSCreate"
                    TesttoolRunner.RunTool(New UPSCreate(TestToolConfiguration.GetInstance().GetScriptPath() + scenarioNode.SelectSingleNode("Template").InnerText), TesttoolRunner.TestSessionFileName_UPS_CLIENT)
                Case "SendUPSWorklistQuery"
                    TesttoolRunner.RunTool(New UPSWorklistQuery(TestToolConfiguration.GetInstance().GetScriptPath() + scenarioNode.SelectSingleNode("Template").InnerText), TesttoolRunner.TestSessionFileName_UPS_CLIENT)
                Case "SendUPSInProgress"
                    TesttoolRunner.RunTool(New UPSInProgess(), TesttoolRunner.TestSessionFileName_UPS_CLIENT)
                Case "SendUPSProgressUpdate"
                    TesttoolRunner.RunTool(New UPSProgressUpdate(TestToolConfiguration.GetInstance().GetScriptPath() + scenarioNode.SelectSingleNode("Template").InnerText), TesttoolRunner.TestSessionFileName_UPS_CLIENT)
                Case "SendUPSFinalUpdate"
                    TesttoolRunner.RunTool(New UPSFinalUpdate(TestToolConfiguration.GetInstance().GetScriptPath() + scenarioNode.SelectSingleNode("Template").InnerText), TesttoolRunner.TestSessionFileName_UPS_CLIENT)
                Case "SendUPSCompletedOrCanceled"
                    TesttoolRunner.RunTool(New UPSCompletedOrCancelled(scenarioNode.SelectSingleNode("isCompleted").InnerText), TesttoolRunner.TestSessionFileName_UPS_CLIENT)
                Case Else

            End Select
        Next

    End If

    End Sub

End Module