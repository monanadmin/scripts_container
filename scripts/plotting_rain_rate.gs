*
*  plotting_rain_rate.gs  -  MONAN precipitation rate (mm/h) - initial version
*
*  Computes, for each interval between consecutive outputs:
*     convective     = (rainc(t)  - rainc(t-1))  / dt
*     non-convective = (rainnc(t) - rainnc(t-1)) / dt
*     total          = convective + non-convective
*  and produces one PNG figure per time with three stacked panels.
*
*  Usage (portrait mode, no window):
*     grads -pbc "run plotting_rain_rate.gs monan.ctl 3"
*     grads -pbc "run plotting_rain_rate.gs monan.ctl 1"
*
*  The second argument is the interval between outputs in hours
*  (e.g. 1 or 3). It must match the tdef of the ctl.
*
*  Assumptions:
*     - the ctl opens the full series of files (options template);
*     - rainc and rainnc are accumulations in mm;
*     - outputs at a constant interval (e.g. every 1 h or every 3 h).
*
*  Script adapted and converted to GrADS, originally from
*     "plotting_rain_rates.py" @Lianet
*
* 

function main(args)

   ctl = subwrd(args,1)
   dt  = subwrd(args,2)

   if (ctl = '' | dt = '')
      say ''
      say 'Usage: grads -pc "run plotting_rain_rate.gs <file.ctl> <dt_hours>"'
      say ''
      say 'or, from inside grads:'
      say ''
      say 'Usage: plotting_rain_rate.gs <file.ctl> <dt_hours>'
      say ''
      say 'dt_hours: interval between outputs in hours (e.g. 1 or 3)'
      say ''
      return
   endif

   if (valnum(dt) = 0)
      say ''
      say 'Error: dt_hours must be a number (e.g. 1 or 3); got: 'dt
      say ''
      return
   endif


   'reinit'
   'open 'ctl

*  Number of times in the ctl
   'q file'

   lin  = sublin(result,5)
   tmax = subwrd(lin,12)  
   

*  Initialization date = first time
   'set t 1'
   'q time'
   argument=subwrd(result,3)
   init = yyyymmddhh(argument)
   
   
*  Creating the figures directory, if it does not exist:   
   '!mkdir -p rain_rate_figures'
   
   say ''
   say 'Initialization: 'init'  |  times in ctl: 'tmax'  |  dt: 'dt' h'
   say ''
  
*  The first time is used only as a reference
   t = 2

   while (t <= tmax)

*     Start and end of the interval
      'set t 't-1
      'q time'
      tini = subwrd(result,3)
      'set t 't
      'q time'
      tfim = subwrd(result,3)
      tag  = yyyymmddhh(tfim)
      
*     Differences of the accumulations
      'define dc  = rainc  - rainc(t-1)'
      'define dnc = rainnc - rainnc(t-1)'      
      
*     Rates in mm/h; real negative differences become undefined
      'define rc  = maskout(dc,  dc  + 0.000001) / 'dt
      'define rnc = maskout(dnc, dnc + 0.000001) / 'dt
      'define rt  = rc + rnc'
      
      'set display color white'
      'c'

      painel('rt', 'Total precipitation (mm/h)',      7.1, 10.5)
      painel('rc', 'Convective precipitation (mm/h)', 3.6,  7.0)
      painel('rnc', 'Large-scale precipitation (mm/h)', 0.1,  3.5)

*     Main title
      'set vpage off'
      'set string 1 c 6'
      'set strsiz 0.13'
      'draw string 4.25 10.75 MONAN | init 'init' | 'tini' - 'tfim' ('dt' h mean)'
 
*     Writing the figures as png: 
      'gxprint rain_rate_figures/rain_rate_'tag'.png white x850 y1100'
      say 'Figure: rain_rate_figures/rain_rate_'tag'.png'
      
      
      
      
      
      t = t + 1
   endwhile  
   'quit'
return


*----------------------------------------------------------------
* Function that converts '00Z19JAN2026' into '2026011900'
*----------------------------------------------------------------

function yyyymmddhh(gt)

   i = 1
   while (substr(gt,i,1) != 'Z')
      i = i + 1
   endwhile

   hh   = substr(gt,1,2)
   dd   = substr(gt,i+1,2)
   mmm  = substr(gt,i+3,3)
   yyyy = substr(gt,i+6,4) 

   meses = 'JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC'
   m = 1

   while (subwrd(meses,m) != mmm)
      m = m + 1
   endwhile

   if (m < 10)
      mm = '0'm
   else
      mm = m
   endif

return yyyy''mm''dd''hh


*----------------------------------------------------------------
* Draws a panel in a vertical strip of the page
*----------------------------------------------------------------

function painel(expr, titulo, y1, y2)

   'set vpage 0 8.5 'y1' 'y2
   'set grads off'
   'set mpdset mres'
   'set gxout shaded'

*  Color palette (blue -> green -> yellow -> red -> purple)
   'set rgb 16 180 240 250'
   'set rgb 17 100 200 250'
   'set rgb 18  30 150 240'
   'set rgb 19   0 200 120'
   'set rgb 20 120 230  50'
   'set rgb 21 250 240  50'
   'set rgb 22 250 170  30'
   'set rgb 23 240  90  20'
   'set rgb 24 200  20  20'
   'set rgb 25 130   0  90'
 
*  Same scale for all panels and times (below 0.1 = white)
   'set clevs 0.1 0.5 1 2 5 10 20 30 50 100'
   'set ccols 0 16 17 18 19 20 21 22 23 24 25'
 
   'set grads off'
   'd 'expr
   'cbarn 0.6'
   'draw title 'titulo

return
