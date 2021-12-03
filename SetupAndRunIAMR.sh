#!/bin/bash
#
### Doccumentation string for help.
if [ "$1" = "-h"  -o "$1" = "--help" ]     # Request help.
then
  echo; printf "This bash script initialises a target directory in which to record the raw data from an IAMR replication of the rotating table experiment.\nThe initialised directory will automatically use the defined perameters to create a save path such that the target directory will be grouped \nwith IAMR simulations in a similar parameter space."; echo
  echo; printf "Usage: \n$ $0 omega=<Rotation Rate> deltah=<Initial Step Height> deltax=<Barrier Offset> <Optional Parameters>\n"; echo
  sed --silent -e '/DOCUMENTATIONXX$/,/^DOCUMENTATIONXX$/p' "$0" |
  sed -e '/DOCUMENTATIONXX$/d'; exit $DOC_REQUEST; fi


: <<DOCUMENTATIONXX
------------------------------------------------------------------------------------------------------

Main parameters:
If not defined the code will abort.

omega: The rotation rate in radians per second.
deltah: The initial step height at zero time in meters.
deltax: Barrier offset from the tank center in meters.

------------------------------------------------------------------------------------------------------

Optional Parameters:
These perameters are set to default values (as shown in brackets) if not defined by the user.

....Tank set-up....
rho1: Density of the homogeneous upper fluid layer in kilograms per meter cubed. (1025 kgm^-3)
rho2: Midpoint density between the two homogeneous fluid layers in kilograms per meter cubed. ([rho1+rho3]/2 kgm^-3)
rho3: Density of the homogeneous lower fluid layer in kilograms per meter cubed. (1030 kgm^-3)
h1: Homogeneous upper layer depth in meters. (0.05m)
h2: Pycnocline width in meters. (0.02m)
h3: Homogeneous lower layer depth in meters. (0.23m)
xwidth: Healing length over which the fluid recovers from the initial step in meters (0.0075m)
turb_scale: Maximum amplitude of the randomised velocity field imposed on the initial state in meters per second. (1e-4 m/s)
boundary_type: Defines the properties of the tank wall as either Noslip or Freeslip. (Noslip) 

....IAMR set-up....
max_step: Maximum iteration number before IAMR shuts down. (4000)
step_time: Maximum simulation time IAMR will progress too. (300)
amr_check_int: Number of iterations between checkpoint files. (1500)
amr_plot_int: Number of iterations between plotfiles. (25)

------------------------------------------------------------------------------------------------------

Please note: In the parent directory there should be the Palette file which contains the visualisation colouring. Additionally the IAMR run3d executable "amr3d.gnu.MPI.ex" and the file "PROB_3D.F90" should be available along the path: 
/mnt/nfs/home/b5035305/aja/IAMR/Exec/run3d/
If this is not the case then the save path should be modified throughout this file.

------------------------------------------------------------------------------------------------------
DOCUMENTATIONXX

### We need to read in all values defined on the command line.
#loop over all arguments given on command line.
for ARGUMENT in "$@"
do

    #Identify input arguments and their values.
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)   

    #Match expected input arguments to that given on the command line.
    case "$KEY" in
	rho1)              rho1=${VALUE} ;;
	rho2)              rho2=${VALUE} ;;
	rho3)              rho3=${VALUE} ;;
	h1)                h1=${VALUE} ;;
	h2)                h2=${VALUE} ;;
	h3)                h3=${VALUE} ;;
	deltah)            deltah=${VALUE} ;;
	deltax)            deltax=${VALUE} ;;
	xwidth)            xwidth=${VALUE} ;;
	omega)             omega=${VALUE};;
	turb_scale)        turb_scale=${VALUE};;
	boundary_type)     boundary_type=${VALUE};;

	max_step)          max_step=${VALUE};;
	stop_time)         stop_time=${VALUE};;
	amr_check_int)     amr_check_int=${VALUE};;
	amr_plot_int)      amr_plot_int=${VALUE};;
        *)   
    esac    
done

### Check if the user has entered needed variables.
if [ -z ${omega+x} ]
then 
    printf "\n'omega' is undefined by user."; 
    printf "\n***ABORTED*** \n'omega' is a key variable and must be defined at the time of execution"
    exit 1 
fi

if [ -z ${deltah+x} ]
then 
    printf "\n'deltah' is undefined by user."; 
    printf "\n***ABORTED*** \n'deltah' is a key variable and must be defined at the time of execution"
    exit 1 
fi

if [ -z ${deltax+x} ]
then 
    printf "\n'deltax' is undefined by user."; 
    printf "\n***ABORTED*** \n'deltax' is a key variable and must be defined at the time of execution"
    exit 1 
fi

#### Hard code the peoblem type to call the correct subroutine in IAMR.
probtype=31
printf "\nThe problem type is set to be probtype=$probtype\n"

### Check if all remaining variables have been defined by the user. If they are undefined they are set to pre-allocated values. rho2 is calculated from the given values of rho1 and rho3.
if [ -z ${boundary_type+x} ]; then printf "\n'boundary_type' is undefined by user. Set to default value Noslip\n"; boundary_type="Noslip"; fi

if [[ $boundary_type == "Noslip" ]]
then
    boundary_number=5
elif [[ $boundary_type == "Freeslip" ]]
then
    boundary_number=4
else 
    printf '\n***ABORTED*** \nThe boundary conditions have been miss defined. Check that we have boundary_type="Noslip" or boundary_type="Freeslip". \n${orig_cam_dir}'
    exit 1
fi

if [ -z ${rho1+x} ]; then printf "\n'rho1' is undefined by user. Set to default value 1025\n"; rho1=1025; fi

if [ -z ${rho3+x} ]; then printf "\n'rho3' is undefined by user. Set to default value 1030\n"; rho3=1030; fi


if [ -z ${rho2+x} ]; then rho2=$(bc <<<'scale=1; (1025+1030)/2'); printf "\n'rho2' is undefined by the user, it was calculated to be rho2=$rho2\n"; fi

if [ -z ${h1+x} ]; then printf "\n'h1' is undefined by user. Set to default value 0.05\n"; h1=0.05; fi

if [ -z ${h2+x} ]; then printf "\n'h2' is undefined by user. Set to default value 0.02\n"; h2=0.02; fi

if [ -z ${h3+x} ]; then printf "\n'h3' is undefined by user. Set to default value 0.23\n"; h3=0.23; fi

if [ -z ${xwidth+x} ]; then printf "\n'xwidth' is undefined by user. Set to default value 0.0075\n"; xwidth=0.0075; fi

if [ -z ${turb_scale+x} ]; then printf "\n'turb_scale' is undefined by user. Set to default value 1.e-4\n"; turb_scale=1.e-4; fi

if [ -z ${max_step+x} ]; then printf "\n'max_step' is undefined by user. Set to default value 4000\n"; max_step=4000; fi

if [ -z ${stop_time+x} ]; then printf "\n'stop_time' is undefined by user. Set to default value 300.0\n"; stop_time=300.0; fi

if [ -z ${amr_check_int+x} ]; then printf "\n'amr_check_int' is undefined by user. Set to default value 1500\n"; amr_check_int=1500; fi

if [ -z ${amr_plot_int+x} ]; then printf "\n'amr_plot_int' is undefined by user. Set to default value 25\n"; amr_plot_int=25; fi

### Define the home directory where the code has been executed and the subsiquent target directory
HOME=$(pwd)
target_dir=$HOME/$boundary_type/rho1_${rho1}_rho3_${rho3}/h1_${h1}_h2_${h2}_h3_${h3}/Omega_$omega/deltah_$deltah/deltax_$deltax

### Check to see if the target directory is pre-existing, if so the code is aborted.
if [[ -d "$target_dir" ]]
then 
    printf "\n***ABORTED*** \nTarget directory already exists, please check you are not trying to override an existing directory. \n${target_dir}\n\n"
    exit 1
fi

### Create the target directory.
printf "\nCreating Directory: \n$target_dir\n\n"
mkdir -p $target_dir

### Generate the probin file
probin_file_name=probin.3d.Tank.${boundary_type}_Omega_${omega}_delh_${deltah}_delx_${deltax}

cat <<EOF > $target_dir/$probin_file_name
x&fortin

  probtype = $probtype

  rho1   = $rho1
  rho2   = $rho2
  rho3   = $rho3
  h1     =    $h1
  h2     =    $h2
  h3     =    $h3
  deltah =    $deltah
  deltax =    $deltax
  xwidth =    $xwidth

 omega = $omega

 turb_scale = $turb_scale
/
EOF

### Generate the inputs file
inputs_file_name=inputs.3d.Tank.${boundary_type}_Omega_${omega}_delh_${deltah}_delx_${deltax}

cat <<EOF > $target_dir/$inputs_file_name

#*******************************************************************************
# INPUTS.3D.RYAN - Rotating Table Replication
#*******************************************************************************

#ns.fixed_dt=1.e-3

#NOTE: You may set *either* max_step or stop_time, or you may set them both.

# Maximum number of coarse grid timesteps to be taken, if stop_time is
#  not reached first.
max_step 		= $max_step

# Time at which calculation stops, if max_step is not reached first.
stop_time 		= $stop_time

# Use the tracer for the refinement criterion
ns.do_tracer_ref = 0
ns.do_vorticity_ref = 0
ns.do_temp_ref = 0

#*******************************************************************************

# Number of cells in each coordinate direction at the coarsest level
amr.n_cell 		= 256 256 128
amr.max_grid_size	= 128

#*******************************************************************************

# Maximum level (defaults to 0 for single level calculation)
amr.max_level		= 0 # maximum number of levels of refinement

#*******************************************************************************

# Interval (in number of level l timesteps) between regridding
amr.regrid_int		= 2 

#*******************************************************************************

# Refinement ratio as a function of level
amr.ref_ratio		= 2 2 2 2

#*******************************************************************************

# Sets the "NavierStokes" code to be verbose
ns.v                    = 1
diffuse.v = 0
mac.v =0
proj.v=1
proj.Pcode = 0
#*******************************************************************************

# Sets the "amr" code to be verbose
amr.v                   = 1

#*******************************************************************************

# Interval (in number of coarse timesteps) between checkpoint(restart) files
amr.check_int		= $amr_check_int 

#*******************************************************************************

# Interval (in number of coarse timesteps) between plot files
amr.plot_int		= $amr_plot_int

#*******************************************************************************

# CFL number to be used in calculating the time step : dt = dx / max(velocity)
ns.cfl                  = 0.7  # CFL number used to set dt

#*******************************************************************************

# Factor by which the first time is shrunk relative to CFL constraint
ns.init_shrink          = 0.1  # factor which multiplies the very first time step

#*******************************************************************************

# Viscosity coefficient 
ns.vel_visc_coef        = 0.00089

#*******************************************************************************

# Diffusion coefficient for first scalar
ns.scal_diff_coefs      = 0.0

#*******************************************************************************

# Forcing term defaults to  rho * abs(gravity) "down"
ns.gravity              = -9.8

#*******************************************************************************

# Name of the file which specifies problem-specific parameters (defaults to "probin")
amr.probin_file 	= $probin_file_name

#*******************************************************************************

# Set to 0 if x-y coordinate system, set to 1 if r-z.
geometry.coord_sys   =  0

#*******************************************************************************

# Physical dimensions of the low end of the domain.
geometry.prob_lo     =  -0.475  -0.475   0.0

# Physical dimensions of the high end of the domain.
geometry.prob_hi     =   0.475   0.475   0.3

#*******************************************************************************

#Set to 1 if periodic in that direction
geometry.is_periodic =  0 0 0

#*******************************************************************************

# Boundary conditions on the low end of the domain.
ns.lo_bc             = $boundary_number $boundary_number $boundary_number

# Boundary conditions on the high end of the domain.
ns.hi_bc             = $boundary_number $boundary_number $boundary_number

# 0 = Interior/Periodic  3 = Symmetry
# 1 = Inflow             4 = SlipWall
# 2 = Outflow            5 = NoSlipWall

#*******************************************************************************

# For solver reasons, use multigrid iterations as the bottom solve.
# mg.usecg = 1

#*******************************************************************************

# Factor by which grids must be coarsenable.
amr.blocking_factor     = 4

#*******************************************************************************

# Add vorticity to the variables in the plot files.
amr.derive_plot_vars    = mag_vort   diveru   avg_pressure

#*******************************************************************************
ns.do_cons_trac=1
ns.do_mom_diff=1
ns.predict_mom_together=1
ns.do_denminmax=1
ns.do_scalminmax=1
EOF

### Add symbolic link to the IAMR run3d executable
ln -s /mnt/nfs/home/b5035305/aja/IAMR/Exec/run3d/amr3d.gnu.MPI.ex $target_dir/amr3d.gnu.MPI.ex

### Add symbolic link to the inputs and output files
ln -s $target_dir/$inputs_file_name $target_dir/inputs
ln -s $target_dir/output.3d.Tank.${boundary_type}_Omega_${omega}_delh_${deltah}_delx_${deltax} $target_dir/outputs

cat <<EOF > $target_dir/DoIAMR
#!/bin/bash
#SBATCH --mail-type=ALL
#SBATCH --mail-user=r.newman2@ncl.ac.uk
#SBATCH -t 04:30:00
#SBATCH -J iamr
#SBATCH --ntasks=32
#SBATCH --error=$target_dir/error.%A
#SBATCH --output=$target_dir/slurm-%A.out

set -x

module list

echo \${SLURM_JOB_NODELIST} 

srun $target_dir/amr3d.gnu.MPI.ex $target_dir/inputs >& outputs
EOF

###Copy Palette and source into the target directory
cp $HOME/Palette $target_dir
cp /mnt/nfs/home/b5035305/aja/IAMR/Exec/run3d/PROB_3D.F90 $target_dir

### Send the job
cd $target_dir
sbatch DoIAMR
cd $HOME
