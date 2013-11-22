/*
 * Copyright (C) 2013 Filip Dobrocky <filip.dobrocky@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtQuick.LocalStorage 2.0
import QtQuick.Window 2.0
import QtMultimedia 5.0
import Ubuntu.Components 0.1
import Ubuntu.Components.Popups 0.1

/*!
    A simple metronome
*/

Window {
    id: mainWindow
    title: "uClick"
    minimumWidth: units.gu(75)
    minimumHeight: units.gu(65)
    width: units.gu(70)
    height: units.gu(60)

    // VARIABLES
    property int count: 1
    property int millis: 0
    property int i: 1
    property int taps: 0
    property int lastTap: 0
    property bool isZero
    property color shapeColor: UbuntuColors.orange

    // SETTINGS
    property string timeSign //time signature string
    property int timeSignCount //number of clicks per beat
    property int timeSignIndex //index of the time signature OptionSelector
    property int accentSound //index of the accent OptionSelector
    property int clickSound //index of the click OptionSelector
    property int bpm: 1 //beats per minute
    property int accentOn //state of the switchAccent
    property int flashOn //animation on/off

    // ABOUT
    property string version: "1.2.5"
    property string about: "<b>uClick " + version + "</b><br><br>uClick is a simple metronome app for Ubuntu.<br><br>Copyright (C) 2013 Filip Dobrocky &lt;filip.dobrocky@gmail.com&gt;"
    property string license: "This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.\n\nThis program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.\n\nYou should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>."

    // DATABASE
    property var db: null

    function openDB() {
        if(db !== null) return;

        // db = LocalStorage.openDatabaseSync(identifier, version, description, estimated_size, callback(db))
        db = LocalStorage.openDatabaseSync("uclick", "0.1", "uClick settings", 100000);

        try {
            db.transaction(function(tx){
                tx.executeSql('CREATE TABLE IF NOT EXISTS settings(key TEXT UNIQUE, value TEXT)');
                var table  = tx.executeSql("SELECT * FROM settings");
                // seed the table with default values
                if (table.rows.length === 0) {
                    tx.executeSql('INSERT INTO settings VALUES(?, ?)', ["timeSign", "4/4"]);
                    tx.executeSql('INSERT INTO settings VALUES(?, ?)', ["timeSignCount", 4]);
                    tx.executeSql('INSERT INTO settings VALUES(?, ?)', ["timeSignIndex", 2]);
                    tx.executeSql('INSERT INTO settings VALUES(?, ?)', ["accentSound", 0]);
                    tx.executeSql('INSERT INTO settings VALUES(?, ?)', ["clickSound", 0]);
                    tx.executeSql('INSERT INTO settings VALUES(?, ?)', ["bpm", 120]);
                    tx.executeSql('INSERT INTO settings VALUES(?, ?)', ["accentOn", 1]);
                    tx.executeSql('INSERT INTO settings VALUES(?, ?)', ["flashOn", 1]);
                    tx.executeSql('INSERT INTO settings VALUES(?, ?)', ["width", 70]);
                    tx.executeSql('INSERT INTO settings VALUES(?, ?)', ["heigth", 60]);
                    console.log('Settings table added');
                };
            });
        } catch (err) {
            console.log("Error creating table in database: " + err);
        };
    }


    function saveSetting(key, value) {
        openDB();
        db.transaction( function(tx){
            tx.executeSql('INSERT OR REPLACE INTO settings VALUES(?, ?)', [key, value]);
        });
    }

    function getSetting(key) {
        openDB();
        var res = "";
        db.transaction(function(tx) {
            var rs = tx.executeSql('SELECT value FROM settings WHERE key=?;', [key]);
            res = rs.rows.item(0).value;
        });
        return res;
    }

    // on startup
    Component.onCompleted: {
        timeSign = getSetting("timeSign")
        timeSignCount = getSetting("timeSignCount")
        timeSignIndex = getSetting("timeSignIndex")
        accentSound = getSetting("accentSound")
        clickSound = getSetting("clickSound")
        bpm = getSetting("bpm")
        accentOn = getSetting("accentOn")
        flashOn = getSetting("flashOn")
        width = getSetting("width")
        height = getSetting("height")
    }

    // on closed
    Component.onDestruction: {
        saveSetting("timeSign", timeSign)
        saveSetting("timeSignCount", timeSignCount)
        saveSetting("timeSignIndex", timeSignIndex)
        saveSetting("accentSound", accentSound)
        saveSetting("clickSound", clickSound)
        saveSetting("bpm", bpm)
        saveSetting("accentOn", accentOn)
        saveSetting("flashOn", flashOn)
        saveSetting("width", width)
        saveSetting("height",height)
    }

    // FUNCTIONS
    function playClick(sound) {
        switch (sound) {
        case 0:
            clickSine.play()
            break;
        case 1:
            clickPluck.play()
            break;
        case 2:
            clickBass.play()
            break;
        }
    }

    function playAccent(sound) {
        switch (sound) {
        case 0:
            accentSine.play()
            break;
        case 1:
            accentPluck.play()
            break;
        case 2:
            accentBass.play()
            break;
        }
    }

    function italian(tempo) {
        if (tempo < 40) return "Larghissimo"
        else if (tempo >= 40 && tempo < 60) return "Largo"
        else if (tempo >= 60 && tempo < 66) return "Larghetto"
        else if (tempo >= 66 && tempo < 76) return "Adagio"
        else if (tempo >= 76 && tempo < 108) return "Adante"
        else if (tempo >= 108 && tempo < 120) return "Modernato"
        else if (tempo >= 120 && tempo < 168) return "Allegro"
        else if (tempo >= 168 && tempo < 208) return "Presto"
        else if (tempo >= 208) return "Prestissimo"
    }

    MainView {
        // objectName for functional testing purposes (autopilot-qt5)
        objectName: "uclick"
        applicationName: "com.ubuntu.developer.filip-dobrocky.uclick"

        backgroundColor: UbuntuColors.coolGrey

        anchors.fill: parent

        Page {
            title: "uClick"
            id: page

            tools: ToolbarItems {
                opened: true
                locked: true

                ToolbarButton {
                    text: "About"
                    iconSource: "icons/about.svg"
                    onTriggered: {
                        PopupUtils.open(sheetAboutComponent)
                    }
                }

                ToolbarButton {
                    iconSource: (flashOn) ? "icons/flash-on.svg" : "icons/flash-off.svg"
                    text: (flashOn) ? "Flash: ON" : "Flash: OFF"
                    onTriggered: {
                        if (flashOn) flashOn = 0
                        else flashOn = 1
                    }
                }

            }

            Component {
                id: sheetAboutComponent

                DefaultSheet {
                    id: sheetAbout
                    title: "About"

                    UbuntuShape {
                        anchors.fill: parent
                        color: UbuntuColors.coolGrey

                        Column {
                            id: columnAbout
                            spacing: units.gu(1)
                            anchors {
                                fill: parent
                                margins: units.gu(1)
                            }

                            Flickable {
                                id: flickableAbout
                                width: parent.width
                                height: parent.height-buttonAbout.height-units.gu(1)
                                contentWidth: labelAbout.width
                                contentHeight: labelAbout.height
                                flickableDirection: Flickable.VerticalFlick
                                clip: true

                                Label {
                                    id: labelAbout
                                    width: columnAbout.width
                                    wrapMode: Text.Wrap
                                    horizontalAlignment: Text.AlignHCenter
                                    text: about
                                }
                            }

                            Button {
                                id: buttonAbout
                                width: parent.width
                                text: "License"
                                onClicked: {
                                    if (!pressed) {
                                        labelAbout.text = license
                                        labelAbout.horizontalAlignment = Text.AlignLeft
                                        pressed = true
                                    } else {
                                        labelAbout.text = about
                                        labelAbout.horizontalAlignment = Text.AlignHCenter
                                        pressed = false
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Column {
                id: column1
                spacing: units.gu(1)
                anchors {
                    margins: units.gu(2)
                    fill: parent
                }

                UbuntuShape {
                    id: shape
                    //color: shapeColor
                    width: parent.width
                    // use all the free height
                    height: parent.height-row1.height-row2.height-labelTempo.height-slider.height-buttonStart.height-units.gu(5)

                    Label {
                        id: label
                        anchors.centerIn: parent
                        color: "white"
                        font.bold: true
                        text: "1"
                        fontSize: "x-large"
                    }

                    SequentialAnimation on color {
                        id: flash
                        running: false
                        ColorAnimation { from: UbuntuColors.coolGrey; to: shapeColor; duration: 0 }
                        ColorAnimation { from: shapeColor; to: UbuntuColors.coolGrey; duration: 60000/bpm*0.4 }

                    }

                }

                Row {
                    id: row1
                    spacing: units.gu(1)
                    width: parent.width

                    Button {
                        id: buttonTap
                        width: 2*(parent.width-units.gu(1))/3
                        text: "Tap"
                        onClicked: {
                            /* on each tap it calculates the average of all of the taps,
                        if the difference is bigger than 25 BPM, it resets the tempo */

                            if (timerTap.running) timerTap.stop()
                            if (millis != 0) {
                                // lastTap can't be zero...
                                if (isZero) {
                                    lastTap = 60000/millis
                                    isZero = false
                                }

                                taps += (60000/millis)

                                // if the difference between taps is greater than 25 BPM, reset
                                if (Math.abs(lastTap-(60000/millis)) > 25) {
                                    i = 1
                                    taps = 0
                                    millis = 0
                                    return
                                }

                                // set tempo to the average of the taps
                                slider.value = (taps/i > 300) ? 300 : taps/i
                                i++
                                lastTap = (60000/millis)
                            } else {
                                isZero = true
                            }

                            millis = 0
                            timerTap.start()
                        }
                    }

                    Component {
                        id: sheetBarComponent

                        DefaultSheet {
                            id: sheetBar
                            doneButton: true
                            title: "Bar"
                            onDoneClicked: {
                                if (textFieldCustom.text != "0" && textFieldCustom.text != ""
                                        && textFieldCustom.text != "00") {
                                    timeSignCount = textFieldCustom.text
                                    timeSign = (timeSignCount == 1) ? timeSignCount + " click"
                                                                    : timeSignCount + " clicks"
                                } else {
                                    switch(timeSign) {
                                    case "2/4":
                                        timeSignCount = 2
                                        break;
                                    case "3/4":
                                        timeSignCount = 3
                                        break;
                                    case "4/4":
                                        timeSignCount = 4
                                        break;
                                    case "5/4":
                                        timeSignCount = 5
                                        break;
                                    case "6/8":
                                        timeSignCount = 6
                                        break;
                                    case "7/8":
                                        timeSignCount = 7
                                        break;
                                    }
                                }
                            }

                            UbuntuShape {
                                anchors.fill: parent
                                color: UbuntuColors.coolGrey

                                Row {
                                    spacing: units.gu(1)
                                    anchors {
                                        fill: parent
                                        margins: units.gu(1)
                                    }

                                    OptionSelector {
                                        model: ["2/4", "3/4", "4/4", "5/4", "6/8", "7/8"]
                                        width: (parent.width-units.gu(1))/2
                                        containerHeight: parent.height
                                        expanded: true
                                        selectedIndex: timeSignIndex
                                        onSelectedIndexChanged: {
                                            timeSign = model[selectedIndex]
                                            timeSignIndex = selectedIndex
                                        }
                                    }

                                    Column {
                                        spacing: units.gu(1)
                                        width: (parent.width-units.gu(1))/2

                                        Label {
                                            text: "Custom:"
                                        }

                                        TextField {
                                            id: textFieldCustom
                                            inputMask: "99"
                                            width: parent.width
                                            hasClearButton: false
                                            placeholderText: "Clicks per bar"
                                        }
                                    }
                                }
                            }
                        }
                    }


                    Button {
                        id: buttonTimeSign
                        width: (parent.width-units.gu(1))/3
                        text: timeSign
                        gradient: UbuntuColors.greyGradient
                        onClicked: PopupUtils.open(sheetBarComponent)
                    }
                }

                Row {
                    id: row2
                    spacing: units.gu(1)
                    width: parent.width

                    Row {
                        spacing: units.gu(1)
                        width: (parent.width-units.gu(1))/3*2

                        Switch {
                            id: switchAccent
                            checked: accentOn
                            onCheckedChanged: {
                                accentOn = checked
                            }
                        }

                        Label {
                            text: "Accent"
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Component {
                        id: sheetSoundComponent

                        DefaultSheet {
                            id: sheetSound
                            doneButton: true
                            title: "Sound"
                            onDoneClicked: {
                                clickSound = selectorClick.selectedIndex
                                accentSound = selectorAccent.selectedIndex
                            }

                            UbuntuShape {
                                anchors.fill: parent
                                color: UbuntuColors.coolGrey

                                Row {
                                    spacing: units.gu(1)
                                    anchors {
                                        fill: parent
                                        margins: units.gu(1)
                                    }

                                    OptionSelector {
                                        id: selectorClick
                                        width: (parent.width-units.gu(1))/2
                                        containerHeight: parent.height
                                        text: "Click"
                                        expanded: true
                                        model: ["Sine", "Pluck", "Bass"]
                                        selectedIndex: clickSound
                                    }

                                    OptionSelector {
                                        id: selectorAccent
                                        width: (parent.width-units.gu(1))/2
                                        containerHeight: parent.height
                                        text: "Accent"
                                        expanded: true
                                        model: ["Sine", "Pluck", "Bass"]
                                        selectedIndex: accentSound
                                    }
                                }
                            }
                        }
                    }

                    Button {
                        id: buttonSound
                        width: (parent.width-units.gu(1))/3
                        text: "Sound"
                        gradient: UbuntuColors.greyGradient
                        onClicked: PopupUtils.open(sheetSoundComponent)
                    }
                }

                Label {
                    id: labelTempo
                    text: "Tempo: " + slider.value.toFixed() + " BPM" + " (" + italian(slider.value.toFixed()) + ")"
                }

                Slider {
                    id: slider
                    width: parent.width
                    minimumValue: 30
                    maximumValue: 300
                    value: bpm
                    onValueChanged: {
                        bpm = slider.value
                        if (timer.running) {
                            timer.stop()
                            timer.start()
                        }
                    }
                }

                Button {
                    id: buttonStart
                    width: parent.width
                    height: units.gu(6)
                    text: "Start"

                    onClicked: {
                        bpm = slider.value
                        if (timer.running == true) {
                            text = "Start"
                            gradient = UbuntuColors.orangeGradient
                            timer.stop()
                            count = 1
                        } else {
                            text = "Stop"
                            gradient = UbuntuColors.greyGradient
                            timer.start()
                        }
                    }
                }

                SoundEffect {
                    id: clickSine
                    source: "sounds/click_sine.wav"
                    volume: 0.8
                }

                SoundEffect {
                    id: accentSine
                    source: "sounds/accent_sine.wav"
                    volume: 1.0
                }

                SoundEffect {
                    id: clickPluck
                    source: "sounds/click_pluck.wav"
                    volume: 0.8
                }

                SoundEffect {
                    id: accentPluck
                    source: "sounds/accent_pluck.wav"
                    volume: 1.0
                }

                SoundEffect {
                    id: clickBass
                    source: "sounds/click_bass.wav"
                    volume: 0.8
                }

                SoundEffect {
                    id: accentBass
                    source: "sounds/accent_bass.wav"
                    volume: 1.0
                }

                Timer {
                    id: timer
                    interval: 60000/bpm; running: false; repeat: true;
                    onTriggered: {
                        if (count == 1 && switchAccent.checked) {
                            shapeColor = "green"
                            playAccent(accentSound)
                        } else {
                            shapeColor = "red"
                            playClick(clickSound)
                        }

                        if (flashOn) flash.start()
                        else shape.color = shapeColor

                        label.text = count
                        count++
                        if (count > timeSignCount) count = 1
                    }
                }

                Timer {
                    id: timerTap
                    // the interval has to be 20ms, it is inaccurate with less
                    interval: 20; running: false; repeat: true;
                    onTriggered: {
                        millis+=20
                        // stop the timer and reset everything if it reaches the highest needed value
                        if (millis > 2000) {
                            timerTap.stop()
                            i = 1
                            taps = 0
                            millis = 0
                        }
                    }
                }
            }
        }
    }
}
