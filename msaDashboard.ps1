# Load Required assemblies
[Void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$Form_msaDashboard = New-Object System.Windows.Forms.Form
    $Form_msaDashboard.BackColor = 'Black'
    $Form_msaDashboard.ClientSize = '900,500'
    $Form_msaDashboard.Text = ' msaDashboard'
    
    $Form_msaDashboard.StartPosition = 'CenterScreen'

    #This makes it borderless
    $Form_msaDashboard.FormBorderStyle = "FixedDialog"
    
    #This makes it always be on top
    $Form_msaDashboard.TopMost = $false

    #These are the control boxes up on the top right
    $Form_msaDashboard.MaximizeBox = $false
    $Form_msaDashboard.MinimizeBox = $true
    $Form_msaDashboard.ControlBox = $true

    #Font being used.
    $Form_msaDashboard.Font = "Consolas"
    
# Added the top label to main dashboard 
# This is referred to as a control, you have to add a line at the end to add the control
# to the form
$label_msaDashboard_Title = New-Object System.Windows.Forms.label
    $label_msaDashboard_Title.Text = "The Save Mart Companies"
    $label_msaDashboard_Title.Location = '10,10'
    $label_msaDashboard_Title.Size = '250,17'
    $label_msaDashboard_Title.ForeColor = 'White'
    $label_msaDashboard_Title.BackColor = 'Black'
    $label_msaDashboard_Title.TextAlign = 'MiddleLeft'
    $label_msaDashboard_Title.Font = "Consolas,13"
    $label_msaDashboard_Title.Anchor = 'Left'

$label_msaDashboard_subTitle = New-Object System.Windows.Forms.Label
    $label_msaDashboard_subTitle.Text = "msaDashboard"
    $label_msaDashboard_subTitle.Location = '10,30'
    $label_msaDashboard_subTitle.Size = '125,20'
    $label_msaDashboard_subTitle.Anchor = 'Left'
    $label_msaDashboard_subTitle.Font = "'Segoe UI Semibold',11"
    $label_msaDashboard_subTitle.BackColor = 'DarkRed'

$label_msaDashboard_redBar = New-Object System.Windows.Forms.Label
    $label_msaDashboard_redBar.Location = '135,30'
    $label_msaDashboard_redBar.Size = '760,2'
    $label_msaDashboard_redBar.Anchor = 'Right'
    $label_msaDashboard_redBar.BackColor = 'DarkRed'

$panel_msaDashboard_leftBack = New-Object System.Windows.Forms.Panel
    $panel_msaDashboard_leftBack.Location = '10,55'
    $panel_msaDashboard_leftBack.Size = '440,400'
    $panel_msaDashboard_leftBack.BackColor = 'DarkGray'
    $panel_msaDashboard_leftBack.AccessibleName = 'Panel_leftBack'

$panel_msaDashboard_leftFront = New-Object System.Windows.Forms.Panel
    $panel_msaDashboard_leftFront.Location = '11,56'
    $panel_msaDashboard_leftFront.Size = '437,397'
    $panel_msaDashboard_leftFront.BackColor = 'Yellow'
    $panel_msaDashboard_leftFront.BringToFront()
    $panel_msaDashboard_leftFront.Parent = 'Panel_LeftBack'
    $panel_msaDashboard_leftFront.Dock = New-Object System.Windows.Forms.DockStyle


$tab_msaDashboard_Tab1 = New-Object System.Windows.Forms.TabPage


$Form_msaDashboard.controls.Add($label_msaDashboard_subTitle)
$Form_msaDashboard.controls.Add($label_msaDashboard_redBar)
$Form_msaDashboard.controls.Add($label_msaDashboard_Title)
$Form_msaDashboard.Controls.add($panel_msaDashboard_leftBack)
$Form_msaDashboard.Controls.add($panel_msaDashboard_leftFront)

[Void] $Form_msaDashboard.ShowDialog()
