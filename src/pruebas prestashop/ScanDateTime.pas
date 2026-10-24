unit ScanDateTime;


interface
uses Windows, DateUtils, SysUtils, Math;

const whitespace  = [' ',#13,#10];
      hrfactor    = 1/(24);
      minfactor   = 1/(24*60);
      secfactor   = 1/(24*60*60);
      mssecfactor = 1/(24*60*60*1000);
const AMPMformatting : array[0..2] of string =('am/pm','a/p','ampm');

function scandatetimer(const pattern:string;const s:string;const fmt:TFormatSettings;startpos:integer=1) : tdatetime;
function scandatetimernof(const pattern:string;const s:string;startpos:integer=1) : tdatetime;

implementation

function scandatetimer(const pattern:string;
                      const s:string;
                      const fmt:TFormatSettings;
                      startpos:integer=1) : tdatetime;
var len ,ind  : integer;
    yy,mm,dd  : integer;
    timeval   : TDateTime;
    activequote: char;
procedure intscandate(ptrn:pchar;plen:integer;poffs:integer);
// poffs is the offset to
var
    pind : integer;
function findimatch(const mnts:array of string;p:pchar):integer;
var i : integer;
    plen, findlen: integer;
begin
  result:=-1;
  i:=0;
  plen := strlen(p);
  while (i<=high(mnts)) and (result=-1) do
    begin
      findlen := length(mnts[i]);
      if (findlen > 0) and (findlen <= plen) then // protect against buffer over-read
        if AnsiStrLIComp(p,@(mnts[i][1]),findlen)=0 then
          result:=i;
      inc(i);
    end;
end;
procedure arraymatcherror;
begin
 // raise.exception(format(<SNoArrayMatch,[pind+1,ind]))
end;
function scanmatch(const mnts : array of string;p:pchar; patlen: integer):integer;
begin
  result:=findimatch(mnts,p);
  if result=-1 then
    arraymatcherror
  else
  begin
    inc(ind,length(mnts[result]));
    inc(pind,patlen);
    inc(result); // was 0 based.
  end;
end;
var pivot,
    i     : integer;
function scanfixedint(maxv:integer):integer;
var c : char;
    oi:integer;
begin
  result:=0;
  oi:=ind;
  c:=ptrn[pind];
  while (pind<plen) and (ptrn[pind]=c) do inc(pind);
  while (maxv>0) and (ind<=len) and (s[ind] IN ['0'..'9']) do
    begin
      result:=result*10+ord(s[ind])-48;
      inc(ind);
      dec(maxv);
    end;
//  if oi=ind then
//    raiseexception(format(SPatternCharMismatch,[c,oi]));
end;
procedure matchchar(c:char);
begin
//  if (ind>len) or (s[ind]<>c) then
//    raiseexception(format(SNoCharMatch,[s[ind],c,pind+poffs+1,ind]));
  inc(pind);
  inc(ind);
end;
function scanpatlen:integer;
var c : char;
    lind : Integer;
begin
  result:=pind;
  lind:=pind;
  c:=ptrn[lind];
  while (lind<=plen) and (ptrn[lind]=c) do
      inc(lind);
  result:=lind-result;
end;
procedure matchpattern(const lptr:string);
var len:integer;
begin
  len:=length(lptr);
  if len>0 then
    intscandate(@lptr[1],len,pind+poffs);
end;
var lasttoken,lch : char;
begin
  pind:=0;     lasttoken:=' ';
  while (ind<=len) and (pind<plen) do
     begin
       lch:=upcase(ptrn[pind]);
       if activequote=#0 then
          begin
            if (lch='M') and (lasttoken='H') then
              begin
                i:=scanpatlen;
//                if i>2 then
//                  raiseexception(format(Shhmmerror,[poffs+pind+1]));
                timeval:=timeval+scanfixedint(2)* minfactor;
              end
            else
            case lch of
               'H':  timeval:=timeval+scanfixedint(2)* hrfactor;
               'D':  begin
                       i:=scanpatlen;
                       case i of
                          1,2 : dd:=scanfixedint(2);
                          3   : dd:=scanmatch(fmt.shortDayNames,@s[ind],i);
                          4   : dd:=scanmatch(fmt.longDayNames,@s[ind],i);
                          5   :
                            begin
                              matchpattern(fmt.shortdateformat);
                              inc(pind, i);
                            end;
                          6   :
                            begin
                              matchpattern(fmt.longdateformat);
                              inc(pind, i);
                            end;
                         end;
                     end;
               'N':  timeval:=timeval+scanfixedint(2)* minfactor;
               'S':  timeval:=timeval+scanfixedint(2)* secfactor;
               'Z':  timeval:=timeval+scanfixedint(3)* mssecfactor;
               'Y':  begin
                       i:=scanpatlen;
                       case i of
                          1,2 : yy:=scanfixedint(2);
                          else  yy:=scanfixedint(i);
                       end;
                       if i<=2 then
                         begin
                           pivot:=YearOf(now)-fmt.TwoDigitYearCenturyWindow;
                           inc(yy, pivot div 100 * 100);
                           if (fmt.TwoDigitYearCenturyWindow > 0) and (yy < pivot) then
                              inc(yy, 100);
                         end;
                      end;
               'M': begin
                       i:=scanpatlen;
                       case i of
                          1,2: mm:=scanfixedint(2);
                          3:   mm:=scanmatch(fmt.ShortMonthNames,@s[ind],i);
                          4:   mm:=scanmatch(fmt.LongMonthNames,@s[ind],i);
                          end;
                    end;
               'T' : begin
                       i:=scanpatlen;
                       case i of
                       1:
                         begin
                           matchpattern(fmt.shorttimeformat);
                           inc(pind, i);
                         end;
                       2:
                         begin
                           matchpattern(fmt.longtimeformat);
                           inc(pind, i);
                         end;
                       end;
                     end;
               'A' : begin
                            i:=findimatch(AMPMformatting,@ptrn[pind]);
                            case i of
                              0: begin
                                   i:=findimatch(['AM','PM'],@s[ind]);
                                   case i of
                                     0: ;
                                     1: timeval:=timeval+12*hrfactor;
                                   else
                                     arraymatcherror
                                     end;
                                   inc(pind,length(AMPMformatting[0]));
                                   inc(ind,2);
                                 end;
                              1: begin
                                    case upcase(s[ind]) of
                                     'A' : ;
                                     'P' : timeval:=timeval+12*hrfactor;
                                   else
                                     arraymatcherror
                                     end;
                                   inc(pind,length(AMPMformatting[1]));
                                   inc(ind);
                                 end;
                               2: begin
                                    i:=findimatch([fmt.timeamstring,fmt.timepmstring],@s[ind]);
                                    case i of
                                     0: inc(ind,length(fmt.timeamstring));
                                     1: begin
                                          timeval:=timeval+12*hrfactor;
                                          inc(ind,length(fmt.timepmstring));
                                        end;
                                   else
                                     arraymatcherror
                                     end;
                                   inc(pind,length(AMPMformatting[2]));
                                 end;
                            else  // no AM/PM match. Assume 'a' is simply a char
                                matchchar(ptrn[pind]);
                             end;
                         end;
               '/' : matchchar(fmt.dateSeparator);
               ':' : begin
                       matchchar(fmt.TimeSeparator);
                       lch:=lasttoken;
                     end;
               #39,'"' : begin
                           activequote:=lch;
                           inc(pind);
                         end;
               'C' : begin
                       intscandate(@fmt.shortdateformat[1],length(fmt.ShortDateFormat),pind+poffs);
                       intscandate(@fmt.longtimeformat[1],length(fmt.longtimeformat),pind+poffs);
                       inc(pind);
                     end;
               '?' : begin
                       inc(pind);
                       inc(ind);
                     end;
               #9  : begin
                       while (ind<=len) and (s[ind] in whitespace) do
                         inc(ind);
                       inc(pind);
                     end;
               else
                 matchchar(ptrn[pind]);
             end; {case}
             lasttoken:=lch;
            end
          else
            begin
              if activequote=lch then
                begin
                  activequote:=#0;
                  inc(pind);
                end
              else
                matchchar(ptrn[pind]);
            end;
     end;
//   if (pind<plen) and (plen>0) and not (ptrn[plen-1] in [#9, '"']) then  // allow omission of trailing whitespace
//     RaiseException(format(SFullpattern,[poffs+pind+1]));
end;
var plen:integer;
begin
  activequote:=#0;
  yy:=0; mm:=0; dd:=0;
  timeval:=0.0;
  len:=length(s); ind:=startpos;
  plen:=length(pattern);
  intscandate(@pattern[1],plen,0);
  result:=timeval;
  if (yy>0) and (mm>0) and (dd>0) then
     result:=result+encodedate(yy,mm,dd);
end;

function scandatetimernof(const pattern:string;
                          const s:string;
                          startpos:integer=1) : tdatetime;
var
  defaultformatSettings:TFormatSettings;
begin
  GetLocaleFormatSettings(LOCALE_SYSTEM_DEFAULT, formatSettings);
  result:=scandatetimer(pattern, s , defaultformatSettings, startpos);
end;

end.
