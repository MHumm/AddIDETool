// Small demo program of the usage of the unit

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
program AddIDEToolProject;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  AddIDETool in 'AddIDETool.pas';

var
  ToolAdder   : TAddIDETool;
  IDEVersions : TIDEVersionList;
  Version     : TIDEVersionRec;

begin
  try
    ToolAdder := TAddIDETool.Create;
    try
      IDEVersions := ToolAdder.GetIDEVersionsList;

      WriteLn('Found configurations:');

      for Version in IDEVersions do
        WriteLn(Version.GetConfigKey + ' (' + Version.GetIDEVersionName +')');

      if ToolAdder.IsInMenu('D:\Projekte\DECGitMaster\Compiled\BIN_IDExx.x_Win32__Demos\Hash_FMX.exe',
                            IDEVersions[0].GetConfigKey) then
        WriteLn('Is in tools')
      else
        WriteLn('Is not in tools');

//      ToolAdder.DeleteTool('D:\Projekte\DECGitMaster\Compiled\BIN_IDExx.x_Win32__Demos\Hash_FMX.exe', IDEVersions);

      ToolAdder.AddTool('',
                        'D:\Projekte\DECGitMaster\Compiled\BIN_IDExx.x_Win32__Demos\Hash_FMX.exe',
                        'FMXHashDemo',
                        'D:\Projekte\DECGitMaster\Compiled\BIN_IDExx.x_Win32__Demos',
                        IDEVersions);
    finally
      ToolAdder.Free;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

  ReadLn;
end.
