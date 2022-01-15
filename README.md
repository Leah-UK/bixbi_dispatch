<h1 align='center'><a href='https://discord.gg/sBfSsEjgMT'>Discord</a></h1>
<p align='center'><a href='https://forum.cfx.re/u/Leah_UK/summary'>FiveM Profile</a> | <a href='https://ko-fi.com/bixbi'>Support Me Here</a><br></p>

---

<h2 align='center'>Information</h2>

A lightweight dispatch system where data is saved on the server instead of the client. This allows for everyone of the same job to see all available dispatches and contribute to them together. When someone deletes the dispatch it will update across every other client.

The menu is created in a way which will allow the user to continue driving (a pursuit(?)) and not have to move their mouse to click on options. To combat griefers there's an optional discord logging system to ensure that people are closing dispatches at the correct time, after dealing with them appropriately. 

---

<h2 align='center'>Sound Installation</h2>

Navigate to your <b>interact-sound</b> installation folder, then go to client > html > sounds. Put both of the supplied sounds into this folder. Open up the <b>interact-sound</b> fxmanifest.lua and change the "files" line to be like the following:

<code>files {
    'client/html/index.html',
    'client/html/sounds/*'
}</code>

---

<h2 align='center'>Requirements</h2>

- OneSync <b>Infinity</b>
- <a href='https://github.com/overextended/es_extended'>"Ox" ESX</a>,<i> You can modify for other frameworks. <b>Please make a PR if you do</b></i>
- <a href='https://github.com/Leah-UK/bixbi_core'>bixbi_core</a>
- <a href='https://github.com/plunkettscott/interact-sound'>Interact Sound</a>

---

<h2 align='center'>Exports</h2>

<b>Create a Dispatch</b>
<code>exports['bixbi_dispatch']:CreateDispatch()</code>

<b>Panic Button</b>
<code>TriggerServerEvent('bixbi_dispatch:PanicButton')</code>
<br><br><u><b>Create Dispatch - Server</b></u><br>
<code>TriggerEvent('bixbi_dispatch:Add', localPlayerId*, jobToAlert, type, message, location*)</code>
<br>
<i><b>*</b> = Optional. If location is nil you need to supply localPlayerId, and vice-versa.</i>

<i>Example:</i> <code>TriggerEvent('bixbi_dispatch:Add', xPlayer.playerId, 'police', 'robbery', 'Someone is robbing a store', nil)</code>

<b>Create Dispatch - Client</b><br><i>Mostly the same as Server</i>

<i>Example:</i> <code>TriggerServerEvent('bixbi_dispatch:Add', GetPlayerServerId(PlayerId()), 'police', 'prisonbreak', 'There is a prison break in progress!', GetEntityCoords(PlayerPedId()))</code>

---

<p align='center'><i>Feel free to modify to your liking. Please keep my name <b>(Leah#0001)</b> in the credits of the fxmanifest. <b>If your modification is a bug-fix I ask that you make a pull request, this is a free script; please contribute when you can.</b></i></p>
