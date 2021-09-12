{*****************************************************************************
  The AddIDETools team (see file NOTICE.txt) licenses this file
  to you under the Apache License, Version 2.0 (the
  "License"); you may not use this file except in compliance
  with the License. A copy of this licence is found in the root directory
  of this project in the file LICENCE.txt or alternatively at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an
  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  KIND, either express or implied.  See the License for the
  specific language governing permissions and limitations
  under the License.
*****************************************************************************}
unit AddIDETool;

interface

uses
  System.SysUtils,
  System.Win.Registry,
  System.Classes,
  Winapi.Windows;

type
  /// <summary>
  ///   Class for adding something to or deleteing from the IDE's tools menu.
  /// </summary>
  TAddIDETool = class(TObject)
  strict private
    /// <summary>
    ///   Provides access to the Windows registry
    /// </summary>
    FRegistry   : TRegistry;
    /// <summary>
    ///   Key name for the Rad Studio subkeys under the Embarcadero node
    /// </summary>
    FBDSKeyName : string;

    /// <summary>
    ///   Search if a certain tool path is already listed under tools and if yes
    ///   returns the registry path of that registry entry
    /// </summary>
    /// <param name="Path">
    ///   Path to search for
    /// </param>
    /// <param name="RegPath">
    ///   Path to the registry key of the IDE version under which to search
    /// </param>
    /// <returns>
    ///   Registry path of the registry node for the tools entry which already
    ///   exists for the path or empty string if the path is not yet added as
    ///   tools entry
    /// </returns>
    function SearchForToolsPath(Path: string; const RegPath: string):string;
    /// <summary>
    ///   Adds a tool to the tools menu of selected Rad Studio IDEs
    /// </summary>
    /// <param name="Params">
    ///   Command line params the IDE shall pass to the tool
    /// </param>
    /// <param name="Path">
    ///   Path and file name of the tool
    /// </param>
    /// <param name="Title">
    ///   Name of the tool in the menu
    /// </param>
    /// <param name="WorkingDir">
    ///   Path which the IDE sets as working dir before calling the tool
    /// </param>
    /// <param name="RegPath">
    ///   Registry key name of the tools menu entries for the processed IDE version
    /// </param>
    procedure DoAddModifyTool(const Params, Path, Title, WorkingDir, RegPath: string);
    /// <summary>
    ///   Determines the Rad Studio root key which contains the subnodes for
    ///   all versions
    /// </summary>
    function GetIDERootKey:string;
  public
    /// <summary>
    ///   Initialize internal fields
    /// </summary>
    constructor Create;
    /// <summary>
    ///   Free internal fields
    /// </summary>
    destructor  Destroy; override;

    /// <summary>
    ///   Returns a list of all installed IDE versions
    /// </summary>
    /// <returns>
    ///   List of all installed IDE versions. The list is always created even if
    ///   no IDE is installed.
    /// </returns>
    function GetIDEVersionsList: TStringList;
    /// <summary>
    ///   Adds a tool to the tools menu of selected Rad Studio IDEs
    /// </summary>
    /// <param name="Params">
    ///   Command line params the IDE shall pass to the tool
    /// </param>
    /// <param name="Path">
    ///   Path and file name of the tool
    /// </param>
    /// <param name="Title">
    ///   Name of the tool in the menu
    /// </param>
    /// <param name="WorkingDir">
    ///   Path which the IDE sets as working dir before calling the tool
    /// </param>
    /// <param name="IDEVersions">
    ///   List of IDE versions the tool shall get added to. If the list contains
    ///   versions not installed they will be ignored. Best is to call
    ///   GetIDEVersionsList and pass that one.
    /// </param>
    procedure AddTool(const Params, Path, Title, WorkingDir: string;
                      IDEVersions: TStringList);
    /// <summary>
    ///   Remove a tools menu entry for a given tool
    /// </summary>
    /// <param name="Path">
    ///   Path and file name of the tool to remove, it will be referenced by that
    /// </param>
    /// <param name="IDEVersions">
    ///   List of IDE versions the tool shall get deleted from. If the list contains
    ///   versions not installed they will be ignored. Best is to call
    ///   GetIDEVersionsList and pass that one.
    /// </param>
    procedure DeleteTool(const Path: string; IDEVersions: TStringList);

    /// <summary>
    ///   Checks whether a certain application is listed in the tools menu of
    ///   a certain IDE version
    /// </summary>
    /// <param name="Path">
    ///   Path and file name of the tool to look for
    /// </param>
    /// <param name="IDEVersion">
    ///   IDE version to check, as returned by GetIDEVersionList
    /// </param>
    /// <returns>
    ///   true if a tool with that path is listed under Tools menu for the
    ///   given IDE version
    /// </returns>
    function IsInMenu(const Path, IDEVersion: string):Boolean;
    /// <summary>
    ///   Determines the "display name" of a BDS version
    /// </summary>
    /// <param name="IDEVersion">
    ///   IDE Version number as returned by GetIDEVersionList
    /// </param>
    /// <returns>
    ///   Display name for that version of if it is not known and empty string
    /// </returns>
    function GetIDEVersionName(IDEVersion: string):string;

    /// <summary>
    ///   Name of the key under the Embarcadero key under which all Rad Studio
    ///   versions are stored in the registry
    /// </summary>
    property RadStudioKeyName : string
      read   FBDSKeyName
      write  FBDSKEyName;
  end;

implementation

const
  /// <summary>
  ///   Root path for EMBT products
  /// </summary>
  IDERootKey       = 'SOFTWARE\Embarcadero\';
  /// <summary>
  ///   Default root key for Rad Studio
  /// </summary>
  DefaultBDSName   = 'BDS';
  /// <summary>
  ///   Tools subkey
  /// </summary>
  ToolsKey         = 'Transfer';

{ TAddIDETool }

procedure TAddIDETool.AddTool(const Params, Path, Title, WorkingDir: string;
  IDEVersions: TStringList);
var
  IDEVersion      : string;
  ExistingRegPath : string;
  RegPath         : string;
begin
  Assert(Assigned(IDEVersions), 'Not created list of IDE versions has been passed');
  Assert(Path <> '', 'Empty path/file name has been specified');
  Assert(Title <> '', 'Empty title has been specified');

  for IDEVersion in IDEVersions do
  begin
    // Skip versions older than D2009
    if (StrToFloat(IDEVersion, TFormatSettings.Create('en-US'))  >= 6.0) then
    begin
      // if registry path to the tools menu list exists
      RegPath := GetIDERootKey + '\' + IDEVersion + '\' + ToolsKey;
      if FRegistry.OpenKey(RegPath, false) then
      begin
        FRegistry.CloseKey;
        // Check if that path is already listed
        ExistingRegPath := SearchForToolsPath(Path, RegPath);

        if (ExistingRegPath = '') then
        begin
          RegPath := RegPath + '\' + Title;
          DoAddModifyTool(Params, Path, Title, WorkingDir, RegPath);
        end
        else
          DoAddModifyTool(Params, Path, Title, WorkingDir, ExistingRegPath);
      end;
    end;
  end;
end;

constructor TAddIDETool.Create;
begin
  inherited;

  FRegistry         := TRegistry.Create;
  FRegistry.RootKey := HKEY_CURRENT_USER;
  FBDSKeyName          := DefaultBDSName;
end;

procedure TAddIDETool.DeleteTool(const Path: string; IDEVersions: TStringList);
var
  IDEVersion      : string;
  ExistingRegPath : string;
  RegPath         : string;
begin
  Assert(Assigned(IDEVersions), 'Not created list of IDE versions has been passed');
  Assert(Path <> '', 'Empty path/file name has been specified');

  for IDEVersion in IDEVersions do
  begin
    // Skip versions older than D2009
    if (StrToFloat(IDEVersion, TFormatSettings.Create('en-US'))  >= 6.0) then
    begin
      // if registry path to the tools menu list exists
      RegPath := GetIDERootKey + '\' + IDEVersion + '\' + ToolsKey;
      if FRegistry.OpenKey(RegPath, false) then
      begin
        FRegistry.CloseKey;
        // Check if that path is already listed
        ExistingRegPath := SearchForToolsPath(Path, RegPath);

        if (ExistingRegPath <> '') then
          FRegistry.DeleteKey(ExistingRegPath);
      end;
    end;
  end;
end;

destructor TAddIDETool.Destroy;
begin
  FRegistry.Free;

  inherited;
end;

procedure TAddIDETool.DoAddModifyTool(const Params, Path, Title, WorkingDir,
  RegPath: string);
begin
  if FRegistry.OpenKey(RegPath, true) then
  begin
    try
      FRegistry.WriteString('Params', Params);
      FRegistry.WriteString('Path', Path);
      FRegistry.WriteString('Title', Title);
      FRegistry.WriteString('WorkingDir', WorkingDir);
    finally
      FRegistry.CloseKey;
    end;
  end;
end;

function TAddIDETool.GetIDERootKey: string;
begin
  Result := IDERootKey + FBDSKeyName;
end;

function TAddIDETool.GetIDEVersionName(IDEVersion: string): string;
begin
  Result := '';

  if (IDEVersion = '22.0') then
    Exit('11.0 Alexandria');

  if (IDEVersion = '21.0') then
    Exit('10.4 Sydney');
  if (IDEVersion = '20.0') then
    Exit('10.3 Rio');
  if (IDEVersion = '19.0') then
    Exit('10.2 Tokyo');
  if (IDEVersion = '18.0') then
    Exit('10.1 Berlin');
  if (IDEVersion = '17.0') then
    Exit('10.0 Seattle');
  if (IDEVersion = '16.0') then
    Exit('XE8');
  if (IDEVersion = '15.0') then
    Exit('XE7');
  if (IDEVersion = '14.0') then
    Exit('XE6');
  if (IDEVersion = '12.0') then
    Exit('XE5');
  if (IDEVersion = '11.0') then
    Exit('XE4');
  if (IDEVersion = '10.0') then
    Exit('XE3');
  if (IDEVersion = '9.0') then
    Exit('XE2');
  if (IDEVersion = '8.0') then
    Exit('XE');
  if (IDEVersion = '7.0') then
    Exit('2010');
  if (IDEVersion = '6.0') then
    Exit('2009');
  if (IDEVersion = '5.0') then
    Exit('2007');
  if (IDEVersion = '4.0') then
    Exit('2006');
  if (IDEVersion = '3.0') then
    Exit('2005');
  if (IDEVersion = '2.0') then
    Exit('8.0 for .net');
end;

function TAddIDETool.GetIDEVersionsList: TStringList;
begin
  Result := TStringList.Create;

  if FRegistry.OpenKey(GetIDERootKey, false) then
  begin
    try
      FRegistry.GetKeyNames(Result);
      FRegistry.CloseKey;
    except
      On e:exception do
        OutputDebugString(PWideChar('Failure retrieving all installed IDE '+
                                    'versions: ' + e.Message));
    end;
  end;
end;

function TAddIDETool.IsInMenu(const Path, IDEVersion: string): Boolean;
begin
  Result := SearchForToolsPath(Path, GetIDERootKey+'\'+IDEVersion+'\'+ToolsKey) <> '';
end;

function TAddIDETool.SearchForToolsPath(Path: string;
                                        const RegPath: string): string;
var
  ToolsKeys : TStringList;
  Registry  : TRegistry;
  Tool      : string;
  ReadPath  : string;
begin
  Assert(Path <> '', 'Empty path specified');
  Assert(RegPath <> '', 'Empty registry path specified');

  Result := '';
  Path   := UpperCase(Path);

  ToolsKeys := TStringList.Create;
  Registry  := TRegistry.Create;
  Registry.RootKey := HKEY_CURRENT_USER;
  try
    if Registry.OpenKey(RegPath, false) then
    begin
      Registry.GetKeyNames(ToolsKeys);
      Registry.CloseKey;

      for Tool in ToolsKeys do
      begin
        if Registry.OpenKey(RegPath + '\' + Tool, false) then
        begin
          ReadPath := UpperCase(Registry.ReadString('Path'));
          Registry.CloseKey;
          if (ReadPath = Path) then
          begin
            Result := RegPath + '\' + Tool;
            Break;
          end;
        end;
      end;
    end;
  finally
    ToolsKeys.Free;
    Registry.Free;
  end;
end;

end.
