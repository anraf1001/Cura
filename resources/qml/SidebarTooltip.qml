// Copyright (c) 2015 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

import UM 1.0 as UM

UM.PointingRectangle {
    id: base;

    width: UM.Theme.getSize("tooltip").width;
    height: label.height + UM.Theme.getSize("tooltip_margins").height * 2;
    color: UM.Theme.getColor("tooltip");

    arrowSize: UM.Theme.getSize("default_arrow").width

    opacity: 0;
    Behavior on opacity { NumberAnimation { duration: 100; } }

    property alias text: label.text;

    property string scroll_text;

    function show(position, enable_scrolling) {

        if (typeof enable_scrolling !== "undefined" && enable_scrolling == true){
            m_timer.isTimerStarted = false

            m_timer.findScrollText(base.scroll_text, false) // this call will store original scroll text and its index
            var result = m_timer.findScrollText(base.scroll_text, true) // this call will perform scroll

            label.text = result
            m_timer.start()
        }


        if(position.y + base.height > parent.height) {
            x = position.x - base.width;
            y = parent.height - base.height;
        } else {
            x = position.x - base.width;
            y = position.y - UM.Theme.getSize("tooltip_arrow_margins").height;
            if(y < 0)
            {
                position.y += -y;
                y = 0;
            }
        }



        base.opacity = 1;
        target = Qt.point(40 , position.y + UM.Theme.getSize("tooltip_arrow_margins").height / 2)
    }

    function hide() {
        base.opacity = 0;

        if (m_timer.isTimerStarted == true){
            m_timer.stop()
            m_timer.original_text = [];
            m_timer.change_index = [];
            m_timer.isTimerStarted = false

            //console.log("STOP TIMER")
        }

    }

    Timer {

        property bool isTimerStarted: false;
        property int timer_max_iterations: 100;

        property var timer_counter: 0;

        property var original_text: [];
        property var change_index: [];

        id: m_timer
        interval: 800; running: false; repeat: true

        onTriggered: {

            if(isTimerStarted == false){
                m_timer.isTimerStarted = true
            }
            else{
                var result = findScrollText(label.text, true)
                label.text = result
            }

            timer_counter++;

            // To be sure that timer will be stop, after number of max iteration it stops self
            if(timer_counter >= timer_max_iterations){
                m_timer.stop()
            }

        }

        function findScrollText(searchText, performScroll){

            var startScrollTag = "<scroll>";
            var endScrollTag = "</scroll>";
            var start_tag_found = false;
            var temp_scroll_text = ""
            var tags_counter = 0

            var temp_start_scrollIndex = 0

            var result = "";

            for (var index = 0; index < searchText.length; index++)
            {

                if(start_tag_found == false)
                {
                    var temp_start = searchText.substring(index, index + 8); // 8 it is length of <scroll>

                    if(temp_start == startScrollTag){
                        start_tag_found = true;
                        temp_scroll_text = "";
                        index += startScrollTag.length;

                        result += startScrollTag // add <scroll>
						index--; // others one symbol will be removed after each iteration
                        temp_start_scrollIndex = index;
                    }
                    else{
                        result += searchText[index];
                    }

                }
                else if(start_tag_found == true)
                {
                    var temp_end = searchText.substring(index, index + 9); // 9 it is length of </scroll>

                    if(temp_end == endScrollTag){

                        var temp_text_length = index - temp_start_scrollIndex;

                        // condition, if the text is less then do not scroll it
                        if (temp_text_length < 10){
							result += temp_scroll_text
							result += endScrollTag
							index += endScrollTag.length;
                        	start_tag_found = false;

							temp_scroll_text = ""
							index--;
                            continue;
                        }

                        // if false then just store default text and its index
                        if(performScroll == false)
                        {
                            m_timer.original_text[tags_counter] = temp_scroll_text;
                            m_timer.change_index[tags_counter] = 0
                            result += temp_scroll_text;
                            result += endScrollTag
                        }
                        else{

                            var reqestObj = {
                                text: m_timer.original_text[tags_counter],
                                index: m_timer.change_index[tags_counter]
                            };

                            var resultObj = scrollText(reqestObj)


                            //update index and text
                            m_timer.change_index[tags_counter] = resultObj.index;
                            var scrolled_text = resultObj.text;

                            result += scrolled_text;
                            result += endScrollTag // </scroll>

                        }

                        tags_counter++
                        index += endScrollTag.length;
                        start_tag_found = false;

						temp_scroll_text = ""
                        index--;
                    }
                    else{
                        temp_scroll_text += searchText[index]
                    }
                }
            }
            //console.log(result)
            return result;

        }

        function scrollText(changeData){

            var original_text = changeData.text;
            var change_index =  changeData.index;

            var maxLength = 10;

            var temp_gap = " " // This is the gap which is added at the end of the sentence
            //TODO if the gap is longer than one space then qml remove it and set one space,
            //to extend the gap between last symbol and new text should be used &nbsp;,

            var temp_original_text = original_text;
            var temp = temp_original_text + temp_gap + temp_original_text;

            var temp_index = change_index;

            var temp_result = temp.substring(temp_index , maxLength + temp_index);


            //reset index
            if (temp_index >= temp_original_text.length + temp_gap.length){
                temp_index = 1
            }
            else{
                temp_index++;
            }

            var resutlObj = {
                text: temp_result,
                index: temp_index
            };

            return resutlObj;
        }
    }

    Label {
        id: label;
        anchors {
            top: parent.top;
            topMargin: UM.Theme.getSize("tooltip_margins").height;
            left: parent.left;
            leftMargin: UM.Theme.getSize("tooltip_margins").width;
            right: parent.right;
            rightMargin: UM.Theme.getSize("tooltip_margins").width;
        }
        wrapMode: Text.Wrap;
        textFormat: Text.RichText
        font: UM.Theme.getFont("default");
        color: UM.Theme.getColor("tooltip_text");
    }
}
