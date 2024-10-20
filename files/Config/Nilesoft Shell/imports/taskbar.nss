﻿menu(type="taskbar" vis=key.shift() pos=0 title=app.name image=\uE249)
{
	item(title="Configuration" image=\uE10A cmd='"@app.cfg"')
	item(title="Gestionnaire" image=\uE0F3 admin cmd='"@app.exe"')
	item(title="Répértoire" image=\uE0E8 cmd='"@app.dir"')
	item(title="Version\t"+@app.ver vis=label col=1)
	item(title="Docs" image=\uE1C4 cmd='https://nilesoft.org/docs')
	item(title="Donner" image=\uE1A7 cmd='https://nilesoft.org/donate')
}
menu(where=@(this.count == 0) type='taskbar' image=icon.settings expanded=true)
{
	menu(title="Apps" image=\uE254)
	{
		item(title='Paint' image=\uE116 cmd='mspaint')
		item(title='Edge' image cmd='@sys.prog32\Microsoft\Edge\Application\msedge.exe')
		item(title='Calculator' image=\ue1e7 cmd='calc.exe')
		item(title=str.res('regedit.exe,-16') image cmd='regedit.exe')
	}
	menu(title='Affichage' image=\uE1FB)
	{
		item(title='En cascade' cmd=command.cascade_windows)
		item(title='Aggrandie' cmd=command.Show_windows_stacked)
		item(title='Cote a cote' cmd=command.Show_windows_side_by_side)
		sep
		item(title='Minimiser' cmd=command.minimize_all_windows)
		item(title='Restaurer' cmd=command.restore_all_windows)
	}
	item(title=title.desktop image=icon.desktop cmd=command.toggle_desktop)
	item(title=title.settings image=icon.settings(auto, image.color1) cmd='ms-settings:')
	item(title='Gestionnaire des taches' sep=both image=icon.task_manager cmd='taskmgr.exe')
	item(title='Barre des taches' sep=both image=inherit cmd='ms-settings:taskbar')
	item(vis=key.shift() title='Redemarrer explorateur' image=\uE254 cmd=command.restart_explorer)
}