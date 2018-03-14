from pathlib import Path
import shutil,os
import logging
import collections
import subprocess
from pytz import UTC
from datetime import datetime
from dateutil.relativedelta import relativedelta
# %% constants dictacted by legacy Fortran code
root = Path(__file__).parents[1]
transcarexe = root/'transconvec'
if os.name == 'nt':
    transcarexe = transcarexe.with_suffix('.exe')
FOK = 'finish.status'
# hard-coded in Fortran
din =  root / 'dir.input'
dout = Path('dir.output')
ddat = root / 'dir.data'
DATCAR = din / 'DATCAR'
precfn =  'dir.input/precinput.dat'  # NOT based on root, MUST be relative!!

def iterbeams(beam, P:dict):
    if isinstance(beam,tuple):  # due to .iterrows()
        beam = beam[1]

    isok = runbeam(beam, P)

    if isok:
        print(f'OK {beam["E1"]:.0f} eV')
    else:
        logging.warning(f'retrying beam{beam["E1"]}')
        isok = runbeam(beam, P)
        if not isok:
            logging.error(f'failed on beam{beam["E1"]} on 2nd try, aborting')


def runbeam(beam, P:dict) -> bool:
    """Run a particular beam energy vs. time"""
# %% copy the Fortran static init files to this directory (simple but robust)
    datinp,odir = setuptranscario(P['rodir'], beam['E1'])
    setupPrecipitation(odir, datinp, beam, P['Q0'])
# %% run the compiled executable
    runTranscar(odir, P['errfn'], P['msgfn'])
#%% check output trivially
    isok = transcaroutcheck(odir, P['errfn'])

    return isok


def cp_parents(files:list, target_dir:Path, origin:Path=None):
    """
    inputs
    ------
    files: list of files to copy (source)
    target_dir: directory to copy into
    origin: non-relative path of source, that needs to be trimmed.

    This function requires Python >= 3.6.

    This acts like bash cp --parents in Python
    inspiration from
    http://stackoverflow.com/questions/15329223/copy-a-file-into-a-directory-with-its-original-leading-directories-appended

    example
    source: /tmp/e/f
    dest: /tmp/a/b/c/d/
    result: /tmp/a/b/c/d/tmp/e/f

    cp_parents('/tmp/a/b/c/d/boo','/tmp/e/f')
    cp_parents('x/hi','/tmp/e/f/g')  --> copies ./x/hi to /tmp/e/f/g/x/hi
    """
#%% make list if it's a string
    if isinstance(files,(str,Path)):
        files = [files]
#%% cleanup user
    files = (Path(f).expanduser() for f in files)   #relative path or absolute path is fine
    target_dir = Path(target_dir).expanduser()
#%% work
    for f in files:
        if origin:
            fsource = f.relative_to(origin).parent
        else:
            fsource = f.parent

        newpath = target_dir / fsource #to make it work like cp --parents, copying absolute paths if specified
        newpath.mkdir(parents=True, exist_ok=True)
        shutil.copy2(f, newpath)


def runTranscar(odir:Path, errfn:Path, msgfn:Path):
    odir = Path(odir).expanduser().resolve()  # MUST have resolve()!!

    with (odir/errfn).open('w')  as ferr, (odir/msgfn).open('w') as fout:
        subprocess.run(f'.{os.sep}{transcarexe.name}', cwd=odir, stdout=fout, stderr=ferr)


def transcaroutcheck(odir:Path,errfn:Path,ok:str='STOP fin normale')->bool:
    """
    checks for text at end of file

    """
    isok = False
    fok = odir / FOK
    try:
        with (odir/errfn).open('r') as ferr:
            last = collections.deque(ferr,1)[0].rstrip('\n')

        if last == ok:
            isok=True
            fok.write_text('true')
            logging.info(f'{odir} completed successfully.')
        else:
            fok.write_text('false')
            logging.warn(f'{odir} ended sim early:  {last}')
    except IOError as e:
        logging.error(f'problem reading transcar output.  {e}' )
    except IndexError as e: # empty file
        fok.write_text('false')
        logging.warn(f'{odir} Transcar may not have finished the sim')

    return isok


def setuptranscario(rodir:Path, beamEnergy:float):
    inp = readTranscarInput(DATCAR)

    odir = Path(rodir).expanduser() / f'beam{beamEnergy:.1f}'

    (odir/'dir.output').mkdir(parents=True, exist_ok=True)
# %% move files where needed for this instantiation
    if not Path(transcarexe).is_file():
        raise FileNotFoundError(f'could not find {transcarexe}. May need to compile Transcar Fortran code:\n python -m pip install -e .')
        
    # precfn is NOT included here!
    flist = [DATCAR, din / inp['precfile'], ddat / 'type', transcarexe]
    flist += [ddat / 'dir.linux/dir.geomag' / s  for s in ['data_geom.bin','igrf90.dat','igrf90s.dat']]
    flist += [ddat / 'dir.linux/dir.projection/varpot.dat']
    #transcar sigsegv on val_fit_ if FELTRANS is blank!
    flist += [ddat / 'dir.linux/dir.cine' / s  for s in ['DATDEG','DATFEL','DATTRANS','flux.flag','FELTRANS']]
    flist += [ddat / 'dir.linux/dir.cine/dir.euvac/EUVAC.dat']
    flist += [ddat / 'dir.linux/dir.cine/dir.seff' /s  for s in ['crsb8','crsphot1.dat','rdtb8']]

    cp_parents(flist, odir, root)

    return inp, odir


def setupPrecipitation(odir:Path, inp,beam, flux0):
    """this writes dir.input/precinput.dat for the first time step, for each beam"""
    ofn = Path(odir).expanduser() / precfn

    E1 = beam['E1']
    E2 = beam['E2']
    pr1 = beam['pr1']
    pr2 = beam['pr2']

    dE =   E2 - E1
    Esum = E2 + E1
    flux = flux0 / 0.5 / Esum / dE
    Elow = E1 - 0.5*(E1 - pr1)
    Ehigh= E2 - 0.5*(E2 - pr2)

    precout = '\n'.join((f"{inp['precipstartsec']}",
                         f'{Elow} {flux}',
                         f'{Ehigh} -1.0',
                         f"{inp['precipendsec']}",'-1.0 -1.0'))


    print('writing', ofn)

    ofn.write_text(precout)


def readTranscarInput(infn):
    '''
    The transcar input file is indexed by line number --this is what the Fortran
      #  code of transcar does, and it's what we do here as well.
    '''
    infn = Path(infn).expanduser()
    hd = {}
    with infn.open('r') as f:
        hd['kiappel'] =           int(f.readline().split()[0])
        hd['precfile'] =              f.readline().split()[0]
        hd['dtsim'] =           float(f.readline().split()[0]) #"dto"
        hd['dtfluid'] =         float(f.readline().split()[0]) #"sortie"
        hd['iyd_ini'] =         int(f.readline().split()[0])
        hd['dayofsim'] =  datetime.strptime(str(hd['iyd_ini']),'%Y%j').replace(tzinfo=UTC)
        hd['simstartUTCsec'] =  float(f.readline().split()[0]) #"tempsini"
        hd['simlengthsec'] =    float(f.readline().split()[0]) #"tempslim"
        hd['jpreci'] =            int(f.readline().split()[0])
        # transconvec calls the next two latgeo_ini, longeo_ini
        hd['latgeo_ini'], hd['longeo_ini'] = [float(a) for a in f.readline().split(None)[0].split(',')]
        hd['tempsconv_1'] =     float(f.readline().split()[0]) #from transconvec, time before precip
        hd['tempsconv'] =       float(f.readline().split()[0]) #from transconvec, time after precip
        hd['step'] =            float(f.readline().split()[0])
        hd['dtkinetic'] =       float(f.readline().split()[0]) #transconvec calls this "postinto"
        hd['vparaB'] =          float(f.readline().split()[0])
        hd['f107ind'] =         float(f.readline().split()[0])
        hd['f107avg'] =         float(f.readline().split()[0])
        hd['apind'] =           float(f.readline().split()[0])
        hd['convecEfieldmVm'] = float(f.readline().split()[0])
        hd['cofo'] =            float(f.readline().split()[0])
        hd['cofn2'] =           float(f.readline().split()[0])
        hd['cofo2'] =           float(f.readline().split()[0])
        hd['cofn'] =            float(f.readline().split()[0])
        hd['cofh'] =            float(f.readline().split()[0])
        hd['etopflux'] =        float(f.readline().split()[0])
        hd['precinfn'] =              f.readline().split()[0]
        hd['precint'] =           int(f.readline().split()[0])
        hd['precext'] =           int(f.readline().split()[0])
        hd['precipstartsec'] =  float(f.readline().split()[0])
        hd['precipendsec'] =    float(f.readline().split()[0])

        # derived parameters not in datcar file
        hd['tstartSim'] =    hd['dayofsim'] + relativedelta(seconds=hd['simstartUTCsec'])
        hd['tendSim'] =      hd['dayofsim'] + relativedelta(seconds=hd['simlengthsec']) #TODO verify this isn't added to start
        hd['tstartPrecip'] = hd['dayofsim'] + relativedelta(seconds=hd['precipstartsec'])
        hd['tendPrecip'] =   hd['dayofsim'] + relativedelta(seconds=hd['precipendsec'])

    return hd
