# Définition UI WPF
function Get-MainWindowXaml {
    return @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Installer Cache Cleaner" Height="720" Width="1100" WindowStartupLocation="CenterScreen" Background="#FFF9FAFB">
    <Grid Margin="16">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
            <Button x:Name="BtnScan" Content="Analyser" Padding="12,6"/>
            <Button x:Name="BtnSimulate" Content="Simulation (rapport)" Padding="12,6"/>
            <Button x:Name="BtnMove" Content="Déplacer sélection" Padding="12,6"/>
            <Button x:Name="BtnDelete" Content="Supprimer sélection" Padding="12,6"/>
            <Button x:Name="BtnChangeToDelete" Content="Changer Move en Delete" Padding="12,6"/>
            <Button x:Name="BtnSaveConfig" Content="Sauver configuration" Padding="12,6"/>
            <TextBox x:Name="TxtSearch" Width="300" Margin="16,0,0,0"/>
            <CheckBox x:Name="ChkShowExcluded" Content="Afficher exclus" Margin="12,0,0,0"/>
        </StackPanel>
        <DataGrid x:Name="GridItems" Grid.Row="1" AutoGenerateColumns="False" HeadersVisibility="Column" CanUserAddRows="False" IsReadOnly="False" AlternatingRowBackground="#FFF3F4F6">
            <DataGrid.Columns>
                <DataGridCheckBoxColumn Binding="{Binding Selected}" Header="Sel" Width="40"/>
                <DataGridTextColumn Binding="{Binding FileName}" Header="Nom" Width="*"/>
                <DataGridTextColumn Binding="{Binding Kind}" Header="Type" Width="80"/>
                <DataGridTextColumn Binding="{Binding SizeMB}" Header="Taille (MB)" Width="100"/>
                <DataGridTextColumn Binding="{Binding InUse}" Header="InUse" Width="70"/>
                <DataGridTextColumn Binding="{Binding Excluded}" Header="Exclu" Width="70"/>
                <DataGridTextColumn Binding="{Binding Manufacturer}" Header="Éditeur" Width="150"/>
                <DataGridTextColumn Binding="{Binding ProductName}" Header="Produit" Width="200"/>
                <DataGridTextColumn Binding="{Binding Reason}" Header="Raison" Width="200"/>
                <DataGridComboBoxColumn Header="Action" SelectedItemBinding="{Binding SelectedAction}" Width="120">
                    <DataGridComboBoxColumn.ItemsSource>
                        <x:Array Type="{x:Type sys:String}" xmlns:sys="clr-namespace:System;assembly=mscorlib">
                            <sys:String>None</sys:String>
                            <sys:String>Move</sys:String>
                            <sys:String>Delete</sys:String>
                        </x:Array>
                    </DataGridComboBoxColumn.ItemsSource>
                </DataGridComboBoxColumn>
                <DataGridTextColumn Binding="{Binding Path}" Header="Chemin" Width="300"/>
            </DataGrid.Columns>
        </DataGrid>
        <GroupBox Grid.Row="2" Header="Exclusions &amp; Options" Padding="8" Margin="0,8,0,0">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0">
                    <TextBlock Text="Vendors (regex)"/>
                    <TextBox x:Name="TxtVendors" AcceptsReturn="True" Height="80" TextWrapping="Wrap"/>
                </StackPanel>
                <StackPanel Grid.Column="1">
                    <TextBlock Text="Produits (regex)"/>
                    <TextBox x:Name="TxtProducts" AcceptsReturn="True" Height="80" TextWrapping="Wrap"/>
                </StackPanel>
                <StackPanel Grid.Column="2">
                    <TextBlock Text="Fichiers (regex)"/>
                    <TextBox x:Name="TxtFiles" AcceptsReturn="True" Height="80" TextWrapping="Wrap"/>
                </StackPanel>
                <StackPanel Grid.Column="3" VerticalAlignment="Center" Margin="12,0,0,0">
                    <CheckBox x:Name="ChkRecommendMove" Content="Recommander Move"/>
                    <CheckBox x:Name="ChkInspectMeta" Content="Lire métadonnées MSI/MSP"/>
                </StackPanel>
            </Grid>
        </GroupBox>
    </Grid>
</Window>
"@
}
