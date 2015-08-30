with Tree_Test_Suite;
with AUnit.Run;
with AUnit.Reporter.Text;

procedure Run_Tree_Test is
    procedure Run is new AUnit.Run.Test_Runner (Tree_Test_Suite.Suite);
    Reporter: AUnit.Reporter.Text.Text_Reporter;
begin
    Reporter.Set_Use_ANSI_Colors(True); -- colored output
    Run(Reporter);
end Run_Tree_Test;
