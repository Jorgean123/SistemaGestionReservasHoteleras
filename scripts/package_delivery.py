from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
root=Path(__file__).resolve().parents[1]
out=root/'entrega';out.mkdir(exist_ok=True)
dest=out/'SistemaGestionReservasHoteleras_APF1.zip'
with ZipFile(dest,'w',ZIP_DEFLATED) as z:
    for folder in ['src','config','sql','scripts','docs']:
        for path in (root/folder).rglob('*'):
            if path.is_file() and '__pycache__' not in str(path) and not path.name.startswith('~$'):
                updated=root/'docs/Informe_APF1_actualizado.docx'
                if path==root/'docs/Informe_APF1.docx' and updated.exists():
                    continue
                archive_path='docs/Informe_APF1.docx' if path==updated else path.relative_to(root)
                z.write(path,archive_path)
    for file in ['pom.xml','README.md','.gitignore']:z.write(root/file,file)
    z.write(root/'target/hotel.war','distribucion/hotel.war')
with ZipFile(dest) as z:
    assert z.testzip() is None
    assert not any('.tools/' in n or '.git/' in n or n.endswith('hotel-db.properties') for n in z.namelist())
print(str(dest))
