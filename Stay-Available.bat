<# : batch
@echo off
start "" powershell -NoProfile -Sta -ExecutionPolicy Bypass -WindowStyle Hidden -Command "iex ((Get-Content -LiteralPath '%~f0' -Encoding UTF8) -join [char]10)"
exit /b
#>

# Stay Available - keeps Microsoft Teams showing you as Available.
# While on, presses F15 (a key no app uses) every 60 seconds, keeps the
# computer from sleeping, and disables manual locking (Win+L) through the
# per-user DisableLockWorkstation policy. Closing the window turns it all off.

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class KeepAwake {
    [DllImport("user32.dll")]
    static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    [DllImport("kernel32.dll")]
    static extern uint SetThreadExecutionState(uint esFlags);

    public static void PressF15() {
        keybd_event(0x7E, 0, 0, UIntPtr.Zero);
        keybd_event(0x7E, 0, 2, UIntPtr.Zero);
    }
    public static void Hold()    { SetThreadExecutionState(0x80000003); }
    public static void Release() { SetThreadExecutionState(0x80000000); }
}
"@

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Stay Available" Width="400" Height="400" ResizeMode="CanMinimize"
        WindowStartupLocation="CenterScreen" Background="#F8F9FA"
        FontFamily="Segoe UI" TextOptions.TextFormattingMode="Display">
  <Window.Resources>
    <Style x:Key="Pill" TargetType="Button">
      <Setter Property="Cursor" Value="Hand"/>
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
  </Window.Resources>

  <Border Margin="20" Background="White" CornerRadius="16" BorderBrush="#DADCE0" BorderThickness="1" Padding="28,30">
    <StackPanel>
      <TextBlock Text="Stay Available" FontSize="24" Foreground="#202124"/>
      <TextBlock Text="Keeps Microsoft Teams showing you as Available, even when you step away."
                 FontSize="13" Foreground="#5F6368" TextWrapping="Wrap" Margin="0,6,0,24"/>

      <Border Name="StatusPill" CornerRadius="14" Padding="14,6" HorizontalAlignment="Left" Margin="0,0,0,28">
        <StackPanel Orientation="Horizontal">
          <Ellipse Name="StatusDot" Width="10" Height="10" VerticalAlignment="Center" Margin="0,0,8,0"/>
          <TextBlock Name="StatusText" FontSize="13" FontWeight="SemiBold" VerticalAlignment="Center"/>
        </StackPanel>
      </Border>

      <Button Name="ToggleBtn" Style="{StaticResource Pill}"/>

      <TextBlock Text="While on, the computer won't sleep or lock. Turn it off to lock the computer again."
                 FontSize="12" Foreground="#5F6368" TextWrapping="Wrap" Margin="4,14,4,0"/>
    </StackPanel>
  </Border>
</Window>
"@

function Brush($hex) { [Windows.Media.BrushConverter]::new().ConvertFromString($hex) }

$lockKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System"

function Set-LockDisabled($disabled) {
    if ($disabled) {
        if (-not (Test-Path $lockKey)) { New-Item $lockKey -Force | Out-Null }
        Set-ItemProperty $lockKey -Name DisableLockWorkstation -Value 1 -Type DWord
    } else {
        Remove-ItemProperty $lockKey -Name DisableLockWorkstation -ErrorAction SilentlyContinue
    }
}

$win    = [Windows.Markup.XamlReader]::Parse($xaml)
$toggle = $win.FindName("ToggleBtn")
$pill   = $win.FindName("StatusPill")
$dot    = $win.FindName("StatusDot")
$label  = $win.FindName("StatusText")

$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(60)
$timer.Add_Tick({ [KeepAwake]::PressF15() })
$script:isOn = $false

function Set-State($on) {
    $script:isOn = $on
    if ($on) {
        [KeepAwake]::Hold()
        Set-LockDisabled $true
        [KeepAwake]::PressF15()
        $timer.Start()
        $pill.Background   = Brush "#E6F4EA"
        $dot.Fill          = Brush "#1E8E3E"
        $label.Foreground  = Brush "#137333"
        $label.Text        = "On - you'll stay green"
        $toggle.Content    = "Turn off"
        $toggle.Background = Brush "White"
        $toggle.Foreground = Brush "#D93025"
        $toggle.BorderBrush = Brush "#DADCE0"
    } else {
        $timer.Stop()
        [KeepAwake]::Release()
        Set-LockDisabled $false
        $pill.Background   = Brush "#F1F3F4"
        $dot.Fill          = Brush "#9AA0A6"
        $label.Foreground  = Brush "#5F6368"
        $label.Text        = "Off"
        $toggle.Content    = "Turn on"
        $toggle.Background = Brush "#1A73E8"
        $toggle.Foreground = Brush "White"
        $toggle.BorderBrush = Brush "#1A73E8"
    }
}

$toggle.Add_Click({ Set-State (-not $script:isOn) })
$win.Add_Closing({ Set-State $false })
# Make sure locking comes back if Windows shuts down or signs out while on
[Microsoft.Win32.SystemEvents]::add_SessionEnding({ Set-LockDisabled $false })

Set-State $false
[void]$win.ShowDialog()
