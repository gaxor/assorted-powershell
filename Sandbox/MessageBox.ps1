# MessageBox Class
# https://msdn.microsoft.com/en-us/library/system.windows.messagebox(v=vs.110).aspx
[System.Windows.Window.Owner] $Window
# Expecting type: System.Windows.Window.Owner
[String] $Message
[String] $Title
[System.Windows.MessageBoxButton] $MessageBoxButton
# Available options:
# OK
# OKCancel
# YesNo
# YesNoCancel
[System.Windows.MessageBoxImage] $MessageBoxImage
[System.Windows.MessageBoxOptions] $MessageBoxOptions
# Available options:
# DefaultDesktopOnly
#     The message box is displayed on the default desktop of the interactive window station. 
#     Specifies that the message box is displayed from a Microsoft .NET Framework windows service application in order to notify the user of an event.
# None
#     No options are set.
# RightAlign
#     The message box text and title bar caption are right-aligned.
# RtlReading
#     All text, buttons, icons, and title bars are displayed right-to-left.
# ServiceNotification

[System.Windows.Forms.MessageBox]::Show($Message, $Title, $MessageBoxButton, $MessageBoxImage, $MessageBoxOptions)