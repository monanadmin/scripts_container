*
*  plotting_radiation_variables.gs  -  MONAN radiation fluxes (W/m2) and
*                                      TOA shortwave albedo - initial version
*
*  Computes, for each interval between consecutive outputs:
*     flux   = (acc(t) - acc(t-1)) / (dt * 3600)     [J/m2 -> W/m2]
*     albedo = flux(acswupt) / flux(acswdnt)         [dimensionless]
*  and produces one PNG figure per time with ten panels (5 rows x 2 cols).
*
*  Usage (portrait mode, no window):
*     grads -pbc "run plotting_radiation_variables.gs monan.ctl 3"
*     grads -pbc "run plotting_radiation_variables.gs monan.ctl 1"
*
*  The second argument is the interval between outputs in hours
*  (e.g. 1 or 3). It must match the tdef of the ctl.
*
*  Assumptions:
*     - the ctl opens the full series of files (options template);
*     - radiation variables are accumulations in J/m2;
*     - outputs at a constant interval (e.g. every 1 h or every 3 h).
*
*  Script adapted and converted to GrADS, originally from
*     "plotting_radiation_variables.py" @Lianet
*
*

function main(args)

   ctl = subwrd(args,1)
   dt  = subwrd(args,2)

   if (ctl = '' | dt = '')
      say ''
      say 'Usage: grads -pbc "run plotting_radiation_variables.gs <file.ctl> <dt_hours>"'
      say ''
      say 'or, from inside grads:'
      say ''
      say 'Usage: plotting_radiation_variables.gs <file.ctl> <dt_hours>'
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

*  Same interval in seconds (J/m2 -> W/m2)
   dts = dt * 3600

*  Accumulated radiation variables, panel titles and scale type
   var.1 = 'aclwupt'
   tit.1 = 'All-sky upward TOA LW (W/m2)'
   typ.1 = 'lw'

   var.2 = 'aclwuptc'
   tit.2 = 'Clear-sky upward TOA LW (W/m2)'
   typ.2 = 'lw'

   var.3 = 'aclwdnb'
   tit.3 = 'All-sky downward sfc LW (W/m2)'
   typ.3 = 'lw'

   var.4 = 'aclwdnbc'
   tit.4 = 'Clear-sky downward sfc LW (W/m2)'
   typ.4 = 'lw'

   var.5 = 'acswdnb'
   tit.5 = 'All-sky downward sfc SW (W/m2)'
   typ.5 = 'sw'

   var.6 = 'acswdnbc'
   tit.6 = 'Clear-sky downward sfc SW (W/m2)'
   typ.6 = 'sw'

   var.7 = 'acswdnt'
   tit.7 = 'All-sky downward TOA SW (W/m2)'
   typ.7 = 'sw'

   var.8 = 'acswupt'
   tit.8 = 'All-sky upward TOA SW (W/m2)'
   typ.8 = 'sw'

   var.9 = 'acswuptc'
   tit.9 = 'Clear-sky upward TOA SW (W/m2)'
   typ.9 = 'sw'

*  Tenth panel: albedo (computed, not read from the files)
   tit.10 = 'All-sky TOA SW albedo'
   typ.10 = 'alb'

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
   '!mkdir -p rad_flux_figures'

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

*     Fluxes in W/m2; real negative differences become undefined
      i = 1
      while (i <= 9)
         'define dif = 'var.i' - 'var.i'(t-1)'
         'define f'i' = maskout(dif, dif + 0.000001) / 'dts
         i = i + 1
      endwhile

*     Albedo = upward TOA SW (f8) / downward TOA SW (f7);
*     undefined where there is no incoming sunlight (night)
      'define dn  = maskout(f7, f7 - 0.000001)'
      'define alb = f8 / dn'

      'set display color white'
      'c'

*     Ten panels in 5 rows x 2 columns
      i = 1
      while (i <= 10)
         row = math_int((i-1)/2) + 1
         col = i - 2*(row-1)

         x1 = (col-1) * 4.25
         x2 = x1 + 4.25
         y2 = 10.5 - (row-1) * 2.08
         y1 = y2 - 2.08

         if (i = 10)
            expr = 'alb'
         else
            expr = 'f'i
         endif

         painel(expr, tit.i, typ.i, x1, x2, y1, y2)
         i = i + 1
      endwhile

*     Main title
      'set vpage off'
      'set string 1 c 6'
      'set strsiz 0.13'
      'draw string 4.25 10.75 MONAN | init 'init' | 'tini' - 'tfim' ('dt' h mean)'

*     Writing the figures as png:
      'gxprint rad_flux_figures/rad_flux_'tag'.png white x1700 y2200'
      say 'Figure: rad_flux_figures/rad_flux_'tag'.png'

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
* Draws a panel in a rectangle of the page
*----------------------------------------------------------------

function painel(expr, titulo, tipo, x1, x2, y1, y2)

   'set vpage 'x1' 'x2' 'y1' 'y2
   'set grads off'
   'set mpdset mres'
   'set gxout shaded'

*  Fixed scale for each type (default GrADS rainbow colors)
   if (tipo = 'sw')
      'set clevs 100 200 300 400 500 600 700 800 900 1000 1100 1200'
   endif
   if (tipo = 'lw')
      'set clevs 50 100 150 200 250 300 350 400 450 500'
   endif
   if (tipo = 'alb')
      'set clevs 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1'
   endif

   'set grads off'
   'd 'expr
   'cbarn 0.5'
   'draw title 'titulo

return
