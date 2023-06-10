import QtQuick 2.0
import MuseScore 3.0

MuseScore {
	menuPath: "Plugins.Auto-Slur Melismas"
	description: qsTr("This plugin automatically add slurs to vocal melismas") + "\n" +
		qsTr("Compatible with MuseScore 3.3 and later.")
	version: "1.0"
	requiresScore: true

	Component.onCompleted : {
		if (mscoreMajorVersion >= 4) {
			title = qsTr("Auto-Slur Melismas") ;
			categoryCode = "notes-rests";
		} //if
	}//Component
	
	onRun: {
		var full = false
		if (!curScore.selection.elements.length) {
			full = true
			cmd('select-all')
		}
		
		curScore.startCmd()
		var changeList = []
		for (var i in curScore.selection.elements) {
			if (curScore.selection.elements[i].type == Element.LYRICS) {
				console.log("lyric found")
				var lyric = curScore.selection.elements[i]
				var cursor = curScore.newCursor()
				for (var j = 0; j < curScore.nstaves; j++) {
					for (var k = 0; k < 4; k++) {
						cursor.staffIdx = j
						cursor.voice = k
						cursor.rewindToTick(lyric.parent.parent.tick)
						
						if (cursor.element) {
							for (var l in cursor.element.lyrics) {
								if (cursor.element.lyrics[l].is(lyric)) {
									if (cursor.element.lyrics[l].lyricTicks.ticks >= cursor.element.duration.ticks) {
										console.log("lyric has a melisma")
										var startNote = noteOrRest(cursor.element)
										
										var endTick = cursor.tick + cursor.element.lyrics[l].lyricTicks.ticks
										var needToTie = false
										while (cursor.tick < endTick) {
											for (var m in cursor.element.notes) {
												if (! cursor.element.notes[m].tieForward) {
													needToTie = true
												}
											}
											cursor.next()
										}
										if (needToTie) {
											console.log("adding slur")
											changeList.push([startNote, noteOrRest(cursor.element)])
										} else {
											console.log("notes are tied. No need to add a slur")
										}
									}									
								}
							}
						}
					}
				}
			}
		}
		
		curScore.selection.clear()
		for (var i in changeList) {
			curScore.selection.select(changeList[i][0], false)
			curScore.selection.select(changeList[i][1], true)
			cmd('add-slur')
		}
		curScore.selection.clear()
		curScore.endCmd()
		smartQuit()
	}//onRun
	
	function noteOrRest(element) {
		return (element.type == Element.REST) ? element : element.notes[0]
	}
	
	function smartQuit() {
		if (mscoreMajorVersion < 4) {Qt.quit()}
		else {quit()}
	}//smartQuit
}//MuseScore
