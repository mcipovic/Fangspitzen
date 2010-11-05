plugin.loadMainCSS();
plugin.addButtonToToolbar("webuiUpdateToggle", "Pause WebUI..", "theWebUI.togglePause()", "help");
plugin.addButtonToToolbar("webuiRefresh", "Refresh WebUI..", "theWebUI.update()", "help");
$("#webuiUpdateToggle").addClass("pause");
plugin.addSeparatorToToolbar("help");

paused = false;

window.onfocus = function()
{
	if(!paused)
		theWebUI.update();
}

window.onblur = function()
{
	stop();	
}

function stop(){
	theWebUI.timer.stop();
	if(theWebUI.updTimer)
		window.clearTimeout(theWebUI.updTimer);	
}

theWebUI.togglePause = function(){
	if(paused)
	{
		$("#webuiUpdateToggle").removeClass("resume");
		$("#webuiUpdateToggle").addClass("pause");
		$("#webuiUpdateToggle").attr("title","Pause WebUI..");

		theWebUI.update();
		paused = false;
	}
	else
	{
		$("#webuiUpdateToggle").removeClass("pause");
		$("#webuiUpdateToggle").addClass("resume");
		$("#webuiUpdateToggle").attr("title","Resume WebUI..");

		stop();
		
		paused = true;
	}
}

theWebUI.forceUpdate = function(){
	if(theWebUI.updTimer)
		window.clearTimeout(theWebUI.updTimer);
	theWebUI.update();
	if(paused){
		stop();	
	}
}


plugin.onRemove = function()
{
	theWebUI.update();
	this.removeSeparatorFromToolbar("webuiUpdateToggle");
	this.removeButtonFromToolbar("webuiUpdateToggle");
	this.removeButtonFromToolbar("webuiRefresh");
}
	