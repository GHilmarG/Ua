function SayGoodbye(CtrlVar)

fclose(RunInfo.File.fid);

fprintf(CtrlVar.fidlog,' Run finishes at %s \n ================           Allt gott �� endirinn er allra bestur!    ======================\n \n',datestr(now));

end