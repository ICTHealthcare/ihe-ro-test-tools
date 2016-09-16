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
Class TestTool
    Inherits DvtkHighLevelInterface.Dicom.Threads.DicomThread

    'has a scenariorunner
    Protected m_scenarioRunner As ScenarioRunner 
    Private imagesFound As Boolean = false
    Private structureSetFound As Boolean = false
    Private allImagesSameFOR As Boolean = true
    Private sendRTPlan As Boolean = false
    Private normalStructureSet As Boolean

    'Constructor
   Public Sub New()
        'We want to report all messages on the same thread, therefor the Reporter needs TestTool object
        'Reporter can than call the methods: WriteErrorNow(), WriteWarningNow() and WriteInformationNow()
        Reporter.GetInstance.SetTestTool(Me)
		
        Dim brtoChooseStructureSetDialog As New ChooseStructureSetDialog
        brtoChooseStructureSetDialog.ShowDialog()

        normalStructureSet = brtoChooseStructureSetDialog.NormalStructureSet

        Dim brtoDosimetricPlannerDataset As New BRTODosimetricPlannerDataset

        Dim brtoGeometricPlannerDataset As New BRTOGeometricPlannerDataset

        if not brtoChooseStructureSetDialog.NormalStructureSet
            brtoDosimetricPlannerDataset.btnSelectStructureSet.Text = "High-Resolution RT Struct file"
        end if

        brtoDosimetricPlannerDataset.ShowDialog()

        Dim doc As Xml.XmlDocument = New Xml.XmlDocument()
        'doc.Load(IO.Path.GetFullPath("\Scripts\EmptyReferenceDataSet.xml")) 
        doc.Load(IO.Path.GetDirectoryName(Session.SessionFileName) + "\Scripts\EmptyReferenceDataSet.xml")

        Dim CTNode1 As Xml.XmlNode = doc.SelectSingleNode("//DataSet").ChildNodes.Item(1)
        Dim STRUCTNode As Xml.XmlNode = doc.SelectSingleNode("//DataSet/RTStructureSet")
        Dim GEOMETRICPLANNode As Xml.XmlNode = doc.SelectSingleNode("//DataSet/RTPlanGeometric")

        If Not (String.IsNullOrEmpty(brtoDosimetricPlannerDataset.tbSelectedImageSet.Text)) Then

            Dim dirInfo As IO.DirectoryInfo = New IO.DirectoryInfo(brtoDosimetricPlannerDataset.tbSelectedImageSet.Text)
            Dim path As String = IO.Path.GetFullPath(IO.Path.GetDirectoryName(Session.SessionFileName) + "..\..\Datasets\Custom\")
            Dim file As IO.FileInfo

            For Each file In New IO.DirectoryInfo(path).GetFiles
                file.Delete()
            Next

            Dim firstImage As Boolean = false
            Dim frameOfReferenceUID As String = ""

            For Each file In dirInfo.GetFiles()
                If (file.Name.EndsWith(".dcm")) Then
                Dim tempImage As New DvtkHighLevelInterface.Dicom.Files.DicomFile
                    Try
                    tempImage.Read(file.FullName)
                        If (tempImage.DataSet(Tags.SOPClassUID).Values(0).ToString() = SOPclass.CTImageSOPClassUID) Then

                            If Not firstImage
                                frameOfReferenceUID = tempImage.DataSet(Tags.FrameofReferenceUID).Values(0).ToString()
                                firstImage = true
                            End If

                            If Not (frameOfReferenceUID = tempImage.DataSet(Tags.FrameofReferenceUID).Values(0).ToString())
                                allImagesSameFOR = false
                            Else
                                file.CopyTo(path + file.Name, True)

                                Dim Child As Xml.XmlNode = doc.CreateNode("element", "CTImage", "")
                                Child.InnerText = file.Name
                                CTNode1.AppendChild(Child)
                                imagesFound = true
                            End If
                         End if
                    Catch ex As Exception
                        Reporter.GetInstance.ReportWarningMessage(file.FullName + " cannot be read by DVTk")
                    End Try
                End If
            Next

            file = new IO.FileInfo(brtoDosimetricPlannerDataset.tbSelectedStructset.Text)
            file.CopyTo(path + file.Name, True)
            STRUCTNode.InnerText = file.Name
            structureSetFound = true

            If Not (String.IsNullOrEmpty(brtoDosimetricPlannerDataset.tbSelectedRTPlan.Text))
                file = new IO.FileInfo(brtoDosimetricPlannerDataset.tbSelectedRTPlan.Text)
                file.CopyTo(path + file.Name, True)
                GEOMETRICPLANNode.InnerText = file.Name
                sendRTPlan = true
            End If

        Else
            Reporter.GetInstance.ReportErrorMessage("Please select a folder with the dataset where all images and the structure set are located")
        End If

        doc.Save(IO.Path.GetDirectoryName(Session.SessionFileName) + "\Scripts\CustomReferenceDataSet.xml")

		m_scenarioRunner = New ScenarioRunner(brtoDosimetricPlannerDataset.tbSelectedStoragePath.Text)
   End Sub

    Protected Overrides Sub Execute()
     If(imagesFound and structureSetFound and allImagesSameFOR)
    	'run scenario
		m_scenarioRunner.RunScenario(New DosimetricPlannerScenario(sendRTPlan, normalStructureSet))
    Else if Not (imagesFound)
        Reporter.GetInstance.ReportErrorMessage("Selected dataset does not have all needed objects")
    Else if Not (allImagesSameFOR)
        Reporter.GetInstance.ReportErrorMessage("Some images are in a different FOR, these images are not used in this scenario")
        m_scenarioRunner.RunScenario(New DosimetricPlannerScenario(sendRTPlan, normalStructureSet))

    End If

		

	End Sub
	
    Public Function WriteErrorNow(ByVal errorText As String)
        WriteError(errorText)
    End Function

    Public Function WriteWarningNow(ByVal warningText As String)
        WriteWarning(warningText)
    End Function

    Public Function WriteInformationNow(ByVal informationText As String)
        WriteInformation(informationText)
    End Function
	
End Class


'Implementation of the main function of DVTk scripts
Module DvtkScript
    ' Entry point of this Visual Basic Script.
    Sub Main(ByVal CmdArgs() As String)

		Dim theExecutablePath As String = System.Windows.Forms.Application.ExecutablePath
        Dim theExecutableName As String = IO.Path.GetFileName(theExecutablePath).ToLower()

#If Not DVT_INTERPRETS_SCRIPT Then
        Dvtk.Setup.Initialize()
#End If
		'create threadmanager
        Dim theDvtThreadManager As DvtkHighLevelInterface.Common.Threads.ThreadManager = New DvtkHighLevelInterface.Common.Threads.ThreadManager
		'Test tool configuration initialisation
		Dim sessionFileName as String
		Dim testtoolconfig As TestToolConfiguration = TestToolConfiguration.GetInstance()
		'Determine the session file aqnd path name
#If DVT_INTERPRETS_SCRIPT Then
        sessionFilename = Session.SessionFileName
#Else
        Dim FilePath As String = Left(System.Windows.Forms.Application.ExecutablePath, InStrRev(System.Windows.Forms.Application.ExecutablePath, "\IHE-RO-TestTool"))
        sessionFileName = FilePath + "DVtkProject\BRTO-II\Sessionfiles\TestTool - BRTO-II - Test.ses"
#End If
		'initialise test tool configuration
        testtoolconfig.Initialise(IO.Path.GetDirectoryName(sessionFileName))

		'creation test tool object
		Dim theTestTool As TestTool = New TestTool()
        theTestTool.Initialize(theDvtThreadManager)
        theTestTool.Options.LogWaitingForCompletionChildThreads = False
		
		'reset the hli activity form window
        DvtkHighLevelInterface.Common.UserInterfaces.HliForm.ResetSingleton()

		'set the test tool properties
#If DVT_INTERPRETS_SCRIPT Then
        theTestTool.Options.DvtkScriptSession = Session
        theTestTool.Options.StartAndStopResultsGatheringEnabled= False
        theTestTool.ResultsGatheringStarted = True
        theTestTool.Options.Identifier = IO.Path.GetFileName(DvtkScriptHostScriptFullFileName).Replace(".", "_")
#Else
        theTestTool.Options.StartAndStopResultsGatheringEnabled = True
        theTestTool.ResultsGatheringStarted = False
        theTestTool.Options.LoadFromFile(sessionFileName)
        'theTestTool.Options.ShowResults = True
        DvtkHighLevelInterface.Common.UserInterfaces.HliForm.GetSingleton().AutoExit = True
        theTestTool.Options.Identifier = "TestTool_vbs"
#End If
		testToolConfig.SetMainThread(theTestTool)
        testToolConfig.SetSession(theTestTool.Options.DvtkScriptSession)
        testToolConfig.SetThreadManager(theDvtThreadManager)

		'start the test tool thread
        theTestTool.Start()
		'wait for the test tool object to finish
        theDvtThreadManager.WaitForCompletionThreads()

#If Not DVT_INTERPRETS_SCRIPT Then
        Dvtk.Setup.Terminate()
#End If
    End Sub 'Main
End Module ' DvtkScript
