<# : batch
@echo off
set "SA_BAT=%~f0"
set "SA_ARGS=%*"
start "" powershell -NoProfile -Sta -ExecutionPolicy Bypass -WindowStyle Hidden -Command "iex ((Get-Content -LiteralPath $env:SA_BAT -Encoding UTF8) -join [char]10)"
exit /b
#>

# Stay Available - keeps Microsoft Teams showing you as Available.
# While on, presses F15 (a key no app uses) every 60 seconds, keeps the
# computer from sleeping, and disables manual locking (Win+L) through the
# per-user DisableLockWorkstation policy. Closing the window turns it all off.
# Optional: a weekly schedule, a one-off "turn off today at" time, dark mode.

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class KeepAwake {
    [DllImport("user32.dll")]
    static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    [DllImport("kernel32.dll")]
    static extern uint SetThreadExecutionState(uint esFlags);
    [DllImport("dwmapi.dll")]
    static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int value, int size);

    public static void PressF15() {
        keybd_event(0x7E, 0, 0, UIntPtr.Zero);
        keybd_event(0x7E, 0, 2, UIntPtr.Zero);
    }
    public static void Hold()    { SetThreadExecutionState(0x80000003); }
    public static void Release() { SetThreadExecutionState(0x80000000); }

    // Dark title bar: attribute 20 on Windows 10 20H1 and later, 19 before that
    public static void DarkTitleBar(IntPtr hwnd, bool dark) {
        int v = dark ? 1 : 0;
        if (DwmSetWindowAttribute(hwnd, 20, ref v, 4) != 0) DwmSetWindowAttribute(hwnd, 19, ref v, 4);
    }
}
"@

$palettes = @{
    light = @{
        WindowBg = "#F8F9FA"; Surface = "#FFFFFF"; Border = "#DADCE0"
        Text = "#202124"; Text2 = "#3C4043"; SubText = "#5F6368"
        Primary = "#1A73E8"; OnPrimary = "#FFFFFF"; Danger = "#D93025"
        OnBg = "#E6F4EA"; OnDot = "#1E8E3E"; OnText = "#137333"
        OffBg = "#F1F3F4"; OffDot = "#9AA0A6"
        Hover = "#F1F3F4"; SelectedBg = "#E8F0FE"; SelectedText = "#1967D2"
    }
    dark = @{
        WindowBg = "#202124"; Surface = "#292A2D"; Border = "#3C4043"
        Text = "#E8EAED"; Text2 = "#E8EAED"; SubText = "#9AA0A6"
        Primary = "#8AB4F8"; OnPrimary = "#202124"; Danger = "#F28B82"
        OnBg = "#26392C"; OnDot = "#81C995"; OnText = "#81C995"
        OffBg = "#3C4043"; OffDot = "#9AA0A6"
        Hover = "#35363A"; SelectedBg = "#394457"; SelectedText = "#8AB4F8"
    }
}

$styles = @"
  <Window.Resources>
    <Style x:Key="Pill" TargetType="Button">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
      <Setter Property="FontSize" Value="15"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Height" Value="48"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border Name="Bg" CornerRadius="24" Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bg" Property="Opacity" Value="0.88"/>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter TargetName="Bg" Property="Opacity" Value="0.75"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="Link" TargetType="Button">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Foreground" Value="{DynamicResource Primary}"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border Name="Bg" Background="Transparent" Padding="2,4">
              <ContentPresenter/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bg" Property="Opacity" Value="0.75"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="Icon" TargetType="Button">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
      <Setter Property="Width" Value="36"/>
      <Setter Property="Height" Value="36"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border Name="Bg" Background="Transparent" CornerRadius="18">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bg" Property="Background" Value="{DynamicResource Hover}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="CheckBox">
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Foreground" Value="{DynamicResource Text2}"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
      <Setter Property="VerticalAlignment" Value="Center"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <StackPanel Orientation="Horizontal" Background="Transparent">
              <Border Name="Box" Width="18" Height="18" CornerRadius="4" BorderThickness="2"
                      BorderBrush="{DynamicResource SubText}" Background="Transparent" VerticalAlignment="Center">
                <Path Name="Mark" Data="M2.5,7 L5.5,10 L11.5,3.5" Stroke="{DynamicResource OnPrimary}" StrokeThickness="2"
                      Visibility="Collapsed" HorizontalAlignment="Center" VerticalAlignment="Center"/>
              </Border>
              <ContentPresenter Margin="10,0,0,0" VerticalAlignment="Center"/>
            </StackPanel>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Box" Property="Background" Value="{DynamicResource Primary}"/>
                <Setter TargetName="Box" Property="BorderBrush" Value="{DynamicResource Primary}"/>
                <Setter TargetName="Mark" Property="Visibility" Value="Visible"/>
              </Trigger>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Box" Property="Opacity" Value="0.85"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="ComboBox">
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Foreground" Value="{DynamicResource Text}"/>
      <Setter Property="Width" Value="84"/>
      <Setter Property="Height" Value="30"/>
      <Setter Property="MaxDropDownHeight" Value="240"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ComboBox">
            <Grid>
              <ToggleButton Focusable="False" ClickMode="Press"
                            IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}">
                <ToggleButton.Template>
                  <ControlTemplate TargetType="ToggleButton">
                    <Border Name="Box" Background="{DynamicResource Surface}" BorderBrush="{DynamicResource Border}" BorderThickness="1" CornerRadius="8">
                      <Path HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,10,0"
                            Data="M0,0 L4,4 L8,0" Stroke="{DynamicResource SubText}" StrokeThickness="1.5"/>
                    </Border>
                    <ControlTemplate.Triggers>
                      <Trigger Property="IsMouseOver" Value="True">
                        <Setter TargetName="Box" Property="BorderBrush" Value="{DynamicResource Primary}"/>
                      </Trigger>
                      <Trigger Property="IsChecked" Value="True">
                        <Setter TargetName="Box" Property="BorderBrush" Value="{DynamicResource Primary}"/>
                      </Trigger>
                    </ControlTemplate.Triggers>
                  </ControlTemplate>
                </ToggleButton.Template>
              </ToggleButton>
              <ContentPresenter IsHitTestVisible="False" Margin="12,0,26,0" VerticalAlignment="Center"
                                Content="{TemplateBinding SelectionBoxItem}"/>
              <Popup IsOpen="{TemplateBinding IsDropDownOpen}" Placement="Bottom" AllowsTransparency="True"
                     Focusable="False" PopupAnimation="Fade">
                <Border Background="{DynamicResource Surface}" BorderBrush="{DynamicResource Border}" BorderThickness="1"
                        CornerRadius="8" Margin="0,4,0,0" Padding="0,4"
                        MinWidth="{TemplateBinding ActualWidth}" MaxHeight="{TemplateBinding MaxDropDownHeight}">
                  <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <ItemsPresenter/>
                  </ScrollViewer>
                </Border>
              </Popup>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Opacity" Value="0.5"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="ScrollBar">
      <Setter Property="Width" Value="10"/>
      <Setter Property="MinWidth" Value="10"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ScrollBar">
            <Track Name="PART_Track" IsDirectionReversed="True" Margin="0,2,3,2">
              <Track.Thumb>
                <Thumb>
                  <Thumb.Template>
                    <ControlTemplate TargetType="Thumb">
                      <Border CornerRadius="3" Width="6" Background="{DynamicResource SubText}" Opacity="0.45"/>
                    </ControlTemplate>
                  </Thumb.Template>
                </Thumb>
              </Track.Thumb>
            </Track>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="ComboBoxItem">
      <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
      <Setter Property="Padding" Value="12,5"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Foreground" Value="{DynamicResource Text}"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ComboBoxItem">
            <Border Name="Row" Background="Transparent" Padding="{TemplateBinding Padding}">
              <ContentPresenter/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsHighlighted" Value="True">
                <Setter TargetName="Row" Property="Background" Value="{DynamicResource Hover}"/>
              </Trigger>
              <Trigger Property="IsSelected" Value="True">
                <Setter TargetName="Row" Property="Background" Value="{DynamicResource SelectedBg}"/>
                <Setter Property="Foreground" Value="{DynamicResource SelectedText}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>
"@

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Stay Available" Width="400" SizeToContent="Height" ResizeMode="CanMinimize"
        WindowStartupLocation="CenterScreen" Background="{DynamicResource WindowBg}"
        FontFamily="Segoe UI" TextOptions.TextFormattingMode="Display">
$styles
  <Border Margin="20" Background="{DynamicResource Surface}" CornerRadius="16" BorderBrush="{DynamicResource Border}" BorderThickness="1" Padding="28,30">
    <StackPanel>
      <Grid>
        <TextBlock Text="Stay Available" FontSize="24" Foreground="{DynamicResource Text}" VerticalAlignment="Center"/>
        <Button Name="ThemeBtn" Style="{StaticResource Icon}" HorizontalAlignment="Right" Margin="0,-6,-10,0"
                AutomationProperties.Name="Dark mode">
          <Viewbox Width="18" Height="18">
            <Canvas Width="24" Height="24">
              <Path Name="MoonIcon" Data="M21,12.79 A9,9 0 1 1 11.21,3 A7,7 0 0 0 21,12.79 Z"
                    Stroke="{DynamicResource SubText}" StrokeThickness="2" StrokeLineJoin="Round"/>
              <Path Name="SunIcon" Visibility="Collapsed"
                    Data="M7,12 A5,5 0 1 0 17,12 A5,5 0 1 0 7,12 Z M12,1 L12,3 M12,21 L12,23 M4.22,4.22 L5.64,5.64 M18.36,18.36 L19.78,19.78 M1,12 L3,12 M21,12 L23,12 M4.22,19.78 L5.64,18.36 M18.36,5.64 L19.78,4.22"
                    Stroke="{DynamicResource SubText}" StrokeThickness="2" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
            </Canvas>
          </Viewbox>
        </Button>
      </Grid>
      <TextBlock Text="Keeps Microsoft Teams showing you as Available, even when you step away."
                 FontSize="13" Foreground="{DynamicResource SubText}" TextWrapping="Wrap" Margin="0,6,0,24"/>

      <Border Name="StatusPill" CornerRadius="14" Padding="14,6" HorizontalAlignment="Left" Margin="0,0,0,28">
        <StackPanel Orientation="Horizontal">
          <Ellipse Name="StatusDot" Width="10" Height="10" VerticalAlignment="Center" Margin="0,0,8,0"/>
          <TextBlock Name="StatusText" FontSize="13" FontWeight="SemiBold" VerticalAlignment="Center"/>
        </StackPanel>
      </Border>

      <Button Name="ToggleBtn" Style="{StaticResource Pill}"/>

      <StackPanel Orientation="Horizontal" Margin="4,20,0,0">
        <CheckBox Name="TodayCheck" Content="Turn off today at"/>
        <ComboBox Name="TodayTime" Margin="12,0,0,0"/>
      </StackPanel>

      <Button Name="ScheduleBtn" Style="{StaticResource Link}" Content="Weekly schedule" HorizontalAlignment="Left" Margin="2,12,0,0"/>

      <TextBlock Text="While on, the computer won't sleep or lock. Turn it off to lock the computer again."
                 FontSize="12" Foreground="{DynamicResource SubText}" TextWrapping="Wrap" Margin="4,16,4,0"/>
    </StackPanel>
  </Border>
</Window>
"@

$dayNames = "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
$dayRows = ""
for ($i = 0; $i -lt 7; $i++) {
    $dayRows += @"
        <CheckBox Name="Day$i" Content="$($dayNames[$i])" Grid.Row="$i" Margin="0,5"/>
        <ComboBox Name="Start$i" Grid.Row="$i" Grid.Column="1"/>
        <TextBlock Text="to" Grid.Row="$i" Grid.Column="2" Foreground="{DynamicResource SubText}" FontSize="13" VerticalAlignment="Center" Margin="10,0"/>
        <ComboBox Name="End$i" Grid.Row="$i" Grid.Column="3"/>
"@
}

$settingsXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Weekly schedule" Width="420" SizeToContent="Height" ResizeMode="NoResize"
        WindowStartupLocation="CenterOwner" ShowInTaskbar="False" Background="{DynamicResource WindowBg}"
        FontFamily="Segoe UI" TextOptions.TextFormattingMode="Display">
$styles
  <Border Margin="20" Background="{DynamicResource Surface}" CornerRadius="16" BorderBrush="{DynamicResource Border}" BorderThickness="1" Padding="28,26">
    <StackPanel>
      <TextBlock Text="Weekly schedule" FontSize="20" Foreground="{DynamicResource Text}"/>
      <TextBlock Text="Stay Available turns on and off by itself at these times. The app has to be open for this to work, minimized is fine."
                 FontSize="12" Foreground="{DynamicResource SubText}" TextWrapping="Wrap" Margin="0,6,0,18"/>

      <CheckBox Name="UseSchedule" Content="Use this schedule" FontWeight="SemiBold" Margin="0,0,0,12"/>

      <Grid Margin="0,0,0,16">
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
          <RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/>
        </Grid.RowDefinitions>
$dayRows
      </Grid>

      <CheckBox Name="StartWithWindows" Content="Start Stay Available when Windows starts"/>

      <TextBlock Name="ErrorText" Foreground="{DynamicResource Danger}" FontSize="12" TextWrapping="Wrap" Margin="0,12,0,0" Visibility="Collapsed"/>

      <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,22,0,0">
        <Button Name="CancelBtn" Content="Cancel" Style="{StaticResource Pill}" Height="40" Width="110"
                Background="{DynamicResource Surface}" Foreground="{DynamicResource Primary}" BorderBrush="{DynamicResource Border}"/>
        <Button Name="SaveBtn" Content="Save" Style="{StaticResource Pill}" Height="40" Width="110" Margin="10,0,0,0"
                Background="{DynamicResource Primary}" Foreground="{DynamicResource OnPrimary}" BorderBrush="{DynamicResource Primary}"/>
      </StackPanel>
    </StackPanel>
  </Border>
</Window>
"@

function Brush($hex) { [Windows.Media.BrushConverter]::new().ConvertFromString($hex) }

$invariant = [Globalization.CultureInfo]::InvariantCulture
$times = for ($m = 0; $m -lt 1440; $m += 15) { "{0:D2}:{1:D2}" -f [int][Math]::Floor($m / 60), ($m % 60) }

# ---- Lock blocking ----

$lockKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System"

function Set-LockDisabled($disabled) {
    if ($disabled) {
        if (-not (Test-Path $lockKey)) { New-Item $lockKey -Force | Out-Null }
        Set-ItemProperty $lockKey -Name DisableLockWorkstation -Value 1 -Type DWord
    } else {
        Remove-ItemProperty $lockKey -Name DisableLockWorkstation -ErrorAction SilentlyContinue
    }
}

# ---- Settings ----

$settingsDir  = Join-Path $env:APPDATA "StayAvailable"
$settingsFile = Join-Path $settingsDir "settings.json"
$startupLink  = Join-Path ([Environment]::GetFolderPath("Startup")) "Stay Available.lnk"

function Load-Settings {
    try {
        if (Test-Path $settingsFile) { return Get-Content $settingsFile -Raw | ConvertFrom-Json }
    } catch {}
    # Default: Sunday to Thursday, 08:00 to 16:00, schedule turned off
    $days = foreach ($i in 0..6) { [pscustomobject]@{ On = ($i -le 4); Start = "08:00"; End = "16:00" } }
    [pscustomobject]@{ UseSchedule = $false; StartWithWindows = $false; Days = @($days) }
}

function Save-Settings($cfg) {
    if (-not (Test-Path $settingsDir)) { New-Item -ItemType Directory $settingsDir | Out-Null }
    $cfg | ConvertTo-Json -Depth 4 | Set-Content $settingsFile -Encoding UTF8
}

function Set-StartWithWindows($on) {
    if ($on -and $env:SA_BAT) {
        $link = (New-Object -ComObject WScript.Shell).CreateShortcut($startupLink)
        $link.TargetPath = $env:SA_BAT
        $link.Arguments = "/min"
        $link.WorkingDirectory = Split-Path $env:SA_BAT
        $link.WindowStyle = 7
        $link.Save()
    } elseif (-not $on) {
        Remove-Item $startupLink -ErrorAction SilentlyContinue
    }
}

# ---- Theme ----

# Until the user picks one, follow the Windows app theme
function Get-Theme {
    if ($script:cfg.Theme -in "light", "dark") { return $script:cfg.Theme }
    $light = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -ErrorAction SilentlyContinue).AppsUseLightTheme
    if ($light -eq 0) { "dark" } else { "light" }
}

function Set-WindowTheme($window) {
    $theme = Get-Theme
    foreach ($entry in $palettes[$theme].GetEnumerator()) { $window.Resources[$entry.Key] = Brush $entry.Value }
    $hwnd = (New-Object Windows.Interop.WindowInteropHelper $window).Handle
    if ($hwnd -ne [IntPtr]::Zero) { [KeepAwake]::DarkTitleBar($hwnd, $theme -eq "dark") }
}

# ---- Schedule logic ----

function Get-TodayWindow($now) {
    if (-not $script:cfg.UseSchedule) { return $null }
    $day = $script:cfg.Days[[int]$now.DayOfWeek]
    if (-not $day.On) { return $null }
    @{ Start = $now.Date + [TimeSpan]::Parse($day.Start); End = $now.Date + [TimeSpan]::Parse($day.End) }
}

function Test-InSchedule($now) {
    $w = Get-TodayWindow $now
    $w -and $now -ge $w.Start -and $now -lt $w.End
}

function Get-NextStart($now) {
    if (-not $script:cfg.UseSchedule) { return $null }
    for ($k = 0; $k -le 7; $k++) {
        $date = $now.Date.AddDays($k)
        $day = $script:cfg.Days[[int]$date.DayOfWeek]
        if ($day.On) {
            $start = $date + [TimeSpan]::Parse($day.Start)
            if ($start -gt $now) { return $start }
        }
    }
    $null
}

# ---- Window ----

$script:cfg = Load-Settings

$win      = [Windows.Markup.XamlReader]::Parse($xaml)
$toggle   = $win.FindName("ToggleBtn")
$pill     = $win.FindName("StatusPill")
$dot      = $win.FindName("StatusDot")
$label    = $win.FindName("StatusText")
$todayChk = $win.FindName("TodayCheck")
$todayCmb = $win.FindName("TodayTime")
$schedBtn = $win.FindName("ScheduleBtn")
$themeBtn = $win.FindName("ThemeBtn")
$moonIcon = $win.FindName("MoonIcon")
$sunIcon  = $win.FindName("SunIcon")

$todayCmb.ItemsSource = $times
$now = Get-Date
$todayCmb.SelectedItem = if ($now.TimeOfDay -lt [TimeSpan]"15:45") { "16:00" } else { "{0:D2}:00" -f (($now.Hour + 1) % 24) }

$pressTimer = New-Object Windows.Threading.DispatcherTimer
$pressTimer.Interval = [TimeSpan]::FromSeconds(60)
$pressTimer.Add_Tick({ [KeepAwake]::PressF15() })

$script:isOn   = $false
$script:offAt  = $null
$script:lastIn = $false

function Update-ThemeIcon {
    $dark = (Get-Theme) -eq "dark"
    $moonIcon.Visibility = if ($dark) { "Collapsed" } else { "Visible" }
    $sunIcon.Visibility  = if ($dark) { "Visible" } else { "Collapsed" }
    [Windows.Automation.AutomationProperties]::SetName($themeBtn, $(if ($dark) { "Light mode" } else { "Dark mode" }))
    $themeBtn.ToolTip = if ($dark) { "Light mode" } else { "Dark mode" }
}

function Update-Status {
    $now = Get-Date
    if ($script:isOn) {
        $w = Get-TodayWindow $now
        if ($script:offAt) { $text = "On - until " + $script:offAt.ToString("HH:mm") }
        elseif (Test-InSchedule $now) { $text = "On - until " + $w.End.ToString("HH:mm") + " (schedule)" }
        else { $text = "On - you'll stay green" }
    } else {
        $next = Get-NextStart $now
        if (-not $next) { $text = "Off" }
        else {
            $daysAway = ($next.Date - $now.Date).Days
            $when = if ($daysAway -eq 0) { "at" } elseif ($daysAway -eq 1) { "tomorrow" }
                    elseif ($daysAway -ge 7) { "next " + $next.ToString("ddd", $invariant) }
                    else { $next.ToString("ddd", $invariant) }
            $text = "Off - turns on $when " + $next.ToString("HH:mm")
        }
    }
    $label.Text = $text
}

# Colors point at theme resources, so switching themes recolors them too
function Set-Colors($element, $property, $key) { $element.SetResourceReference($property, $key) }

function Set-State($on) {
    $script:isOn = $on
    $bg = [Windows.Controls.Control]::BackgroundProperty
    $fg = [Windows.Controls.Control]::ForegroundProperty
    $bb = [Windows.Controls.Control]::BorderBrushProperty
    if ($on) {
        [KeepAwake]::Hold()
        Set-LockDisabled $true
        [KeepAwake]::PressF15()
        $pressTimer.Start()
        Set-Colors $pill ([Windows.Controls.Border]::BackgroundProperty) "OnBg"
        Set-Colors $dot ([Windows.Shapes.Shape]::FillProperty) "OnDot"
        Set-Colors $label ([Windows.Controls.TextBlock]::ForegroundProperty) "OnText"
        $toggle.Content = "Turn off"
        Set-Colors $toggle $bg "Surface"; Set-Colors $toggle $fg "Danger"; Set-Colors $toggle $bb "Border"
    } else {
        $pressTimer.Stop()
        [KeepAwake]::Release()
        Set-LockDisabled $false
        Set-Colors $pill ([Windows.Controls.Border]::BackgroundProperty) "OffBg"
        Set-Colors $dot ([Windows.Shapes.Shape]::FillProperty) "OffDot"
        Set-Colors $label ([Windows.Controls.TextBlock]::ForegroundProperty) "SubText"
        $toggle.Content = "Turn on"
        Set-Colors $toggle $bg "Primary"; Set-Colors $toggle $fg "OnPrimary"; Set-Colors $toggle $bb "Primary"
    }
    Update-Status
}

# "Turn off today at": sets a one-off end time that also overrides the schedule
function Update-OffAt {
    if (-not $todayChk.IsChecked) { $script:offAt = $null; Update-Status; return }
    $at = (Get-Date).Date + [TimeSpan]::Parse($todayCmb.SelectedItem)
    if ($at -le (Get-Date)) { $todayChk.IsChecked = $false; return }
    $script:offAt = $at
    if (-not $script:isOn) { Set-State $true } else { Update-Status }
}

# Runs every 20 seconds. The schedule only acts when its window starts or
# ends, so turning it on or off by hand holds until the next change.
function Invoke-ScheduleCheck {
    $now = Get-Date
    if ($script:offAt -and $now -ge $script:offAt) {
        $todayChk.IsChecked = $false
        Set-State $false
    }
    $in = [bool](Test-InSchedule $now)
    if ($in -ne $script:lastIn) {
        $script:lastIn = $in
        if ($in) { Set-State $true }
        elseif (-not $script:offAt) { Set-State $false }
    }
    Update-Status
}

function Show-Settings {
    $script:sx = [Windows.Markup.XamlReader]::Parse($settingsXaml)
    $script:sx.Owner = $win
    Set-WindowTheme $script:sx
    $script:sx.Add_SourceInitialized({ Set-WindowTheme $script:sx })
    $cfg = $script:cfg
    $script:sx.FindName("UseSchedule").IsChecked = [bool]$cfg.UseSchedule
    $script:sx.FindName("StartWithWindows").IsChecked = [bool]$cfg.StartWithWindows
    for ($i = 0; $i -lt 7; $i++) {
        $script:sx.FindName("Day$i").IsChecked = [bool]$cfg.Days[$i].On
        foreach ($part in "Start", "End") {
            $cmb = $script:sx.FindName("$part$i")
            $cmb.ItemsSource = $times
            $cmb.SelectedItem = $cfg.Days[$i].$part
        }
    }

    $script:sx.FindName("CancelBtn").Add_Click({ $script:sx.Close() })
    $script:sx.FindName("SaveBtn").Add_Click({
        $err = $script:sx.FindName("ErrorText")
        $days = @()
        for ($i = 0; $i -lt 7; $i++) {
            $on    = [bool]$script:sx.FindName("Day$i").IsChecked
            $start = $script:sx.FindName("Start$i").SelectedItem
            $end   = $script:sx.FindName("End$i").SelectedItem
            if ($on -and [TimeSpan]::Parse($end) -le [TimeSpan]::Parse($start)) {
                $err.Text = "On $($dayNames[$i]), the end time needs to be after the start time."
                $err.Visibility = "Visible"
                return
            }
            $days += [pscustomobject]@{ On = $on; Start = $start; End = $end }
        }
        $script:cfg = [pscustomobject]@{
            UseSchedule      = [bool]$script:sx.FindName("UseSchedule").IsChecked
            StartWithWindows = [bool]$script:sx.FindName("StartWithWindows").IsChecked
            Days             = $days
            Theme            = $script:cfg.Theme
        }
        Save-Settings $script:cfg
        Set-StartWithWindows $script:cfg.StartWithWindows
        $script:sx.Close()
    })

    [void]$script:sx.ShowDialog()
    Invoke-ScheduleCheck
}

$toggle.Add_Click({
    if ($script:isOn) { $todayChk.IsChecked = $false; Set-State $false } else { Set-State $true }
})
$todayChk.Add_Checked({ Update-OffAt })
$todayChk.Add_Unchecked({ Update-OffAt })
$todayCmb.Add_SelectionChanged({ if ($todayChk.IsChecked) { Update-OffAt } })
$schedBtn.Add_Click({ Show-Settings })
$themeBtn.Add_Click({
    $next = if ((Get-Theme) -eq "dark") { "light" } else { "dark" }
    $script:cfg | Add-Member -NotePropertyName Theme -NotePropertyValue $next -Force
    Save-Settings $script:cfg
    Set-WindowTheme $win
    Update-ThemeIcon
    # Windows 10 only repaints the title bar after a size change
    $win.Width += 1; $win.Width -= 1
})

$checkTimer = New-Object Windows.Threading.DispatcherTimer
$checkTimer.Interval = [TimeSpan]::FromSeconds(20)
$checkTimer.Add_Tick({ Invoke-ScheduleCheck })

$win.Add_SourceInitialized({ Set-WindowTheme $win })
$win.Add_Closing({ $checkTimer.Stop(); Set-State $false })
# Make sure locking comes back if Windows shuts down or signs out while on
[Microsoft.Win32.SystemEvents]::add_SessionEnding({ Set-LockDisabled $false })

Set-WindowTheme $win
Update-ThemeIcon
Set-State $false
if ($script:cfg.StartWithWindows) { Set-StartWithWindows $true }
Invoke-ScheduleCheck
$checkTimer.Start()
if ($env:SA_ARGS -match "min") { $win.WindowState = "Minimized" }
[void]$win.ShowDialog()
