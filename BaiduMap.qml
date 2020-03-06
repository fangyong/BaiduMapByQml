import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.1
import QtQuick.Controls 1.4
import QtQuick.Window 2.2
import QtQuick.Controls.Styles 1.4

Item {
    id: root
    width: 1000
    height: 1000

    property double longitude: 0;
    property double latitude: 0;
    property double centerTileX: 0;
    property double centerTileY: 0;
    property double startTileX: startPixelX / 256;
    property double startTileY: startPixelY / 256;
    property int mapZoom: 15;
    property double searchX: 0;
    property double searchY: 0;
    property double startX: 0;
    property double startY: 0;
    property double startPixelX: 0;
    property double startPixelY: 0;
    property double centerPixelX: 0;
    property double centerPixelY: 0;
    property int startTileXInt: parseInt(startTileX);
    property int startTileYInt: parseInt(startTileY);
    property int targetTopMargin: parseInt(256 - (startTileY - startTileYInt) * 256);
    property int targetLeftMargin: parseInt((startTileX - startTileXInt) * 256);
    property double mapX: 0;
    property double mapY: 0;
    property int tileRowCount: Math.floor(root.width / 256) + 2
    property int tileColumnCount: Math.floor(root.height / 256) + 2

    property double leftTopLng: 0;
    property double leftTopLat: 0;
    property double rightBottomLng: 0;
    property double rightBottomLat: 0;

    property var sp: [ 1.289059486E7, 8362377.87, 5591021, 3481989.83, 1678043.12, 0 ];

    property int randomNum: 0;

    Rectangle {
        anchors.fill: parent
        color: "white"
        clip: true
        Item {
            id: mapView
            width: 256 * tileRowCount;
            height: 256 * tileColumnCount;
            anchors.top: parent.top;
            anchors.left: parent.left
            anchors.leftMargin: -targetLeftMargin + mapX;
            anchors.topMargin: -targetTopMargin + mapY;
            property int deltaX: 0;
            property int deltaY: 0;
            Repeater {
                id: repeater
                model: tileRowCount * tileColumnCount
                onModelChanged: {
                    calcFourCorner();
                }
                Image {
                    width: 256
                    height: 256
                    x: {
                        var ind = index % tileRowCount + mapView.deltaX
                        if(ind < tileRowCount && ind > -1) {
                            return ind * 256
                        } else {
                            if(ind >= tileRowCount) {
                                return (ind - tileRowCount) * 256
                            }
                            if(ind < 0) {
                                return (ind + tileRowCount) * 256
                            }
                        }
                    }
                    y: {
                        var ind = parseInt(index / tileRowCount) + mapView.deltaY
                        if(ind < tileColumnCount && ind > -1) {
                            return ind * 256
                        } else {
                            if(ind >= tileColumnCount) {
                                return (ind - tileColumnCount) * 256;
                            }
                            if(ind < 0) {
                                return (ind + tileColumnCount) * 256;
                            }
                        }
                    }
                    property var url: {
                        var indx = index % tileRowCount + mapView.deltaX;
                        var indy = parseInt(index / tileRowCount) + mapView.deltaY;
                        if(indx >= tileRowCount)
                            indx = indx - tileRowCount;
                        if(indx < 0)
                            indx = indx + tileRowCount;
                        if(indy >= tileColumnCount)
                            indy = indy - tileColumnCount;
                        if(indy < 0)
                            indy = indy + tileColumnCount;

                        var path = "https://gss" + randomNum + ".bdstatic.com/8bo_dTSlQ1gBo1vgoIiO_jowehsv/tile/?qt=vtile&x=" + parseInt(startTileX + indx) + "&y=" + parseInt(startTileY - indy) + "&z=" + mapZoom + "&styles=pl&scaler=1&udt=20200306"
                        return path;
                    }
                    function update() {
                        source = url;
                    }
                }
            }
        }
        MouseArea {
            anchors.fill: parent
            property point clickPos: "0,0"
            hoverEnabled: true;
            onPressed: {
                clickPos  = Qt.point(mouse.x,mouse.y)
            }
            onReleased: {
                startPixelX += mapX;
                startPixelY -= mapY;
                mapX = 0;
                mapY = 0;
                calcFourCorner();
            }
            onPositionChanged: {
                if(pressed) {
                    var delta = Qt.point(mouse.x-clickPos.x, mouse.y-clickPos.y)
                    root.mapX = root.mapX + delta.x;
                    root.mapY = root.mapY + delta.y;
                    root.centerPixelX = root.centerPixelX - delta.x;
                    root.centerPixelY = root.centerPixelY + delta.y;
                    root.searchX = root.centerPixelX / Math.pow(2, parseInt(mapZoom) - 18);
                    root.searchY = root.centerPixelY / Math.pow(2, parseInt(mapZoom) - 18);

                    clickPos.x = mouse.x;
                    clickPos.y = mouse.y
                    if(root.mapX - targetLeftMargin >= 0) {
                        root.mapX -= 256;
                        startPixelX -= 256;
                        mapView.deltaX++;
                        if(Math.abs(mapView.deltaX) == tileRowCount)
                            mapView.deltaX = 0;
                    }

                    if(root.mapY - targetTopMargin >= 0) {
                        root.mapY -= 256;
                        startPixelY += 256;
                        mapView.deltaY++;
                        if(Math.abs(mapView.deltaY) == tileColumnCount)
                            mapView.deltaY = 0;
                    }

                    if(root.mapX - targetLeftMargin <= -256) {
                        root.mapX += 256;
                        startPixelX += 256;
                        mapView.deltaX--;
                        if(Math.abs(mapView.deltaX) == tileRowCount)
                            mapView.deltaX = 0;
                    }

                    if(root.mapY - targetTopMargin <= -256) {
                        root.mapY += 256;
                        startPixelY -= 256;
                        mapView.deltaY--;
                        if(Math.abs(mapView.deltaY) == tileColumnCount)
                            mapView.deltaY = 0;
                    }
                    updateMapView();
                }
            }
            onWheel: {
                var currentPixelX = startPixelX + wheel.x;
                var currentPixelY = startPixelY - wheel.y;
                var currentX = currentPixelX / Math.pow(2, parseInt(mapZoom) - 18);
                var currentY = currentPixelY / Math.pow(2, parseInt(mapZoom) - 18);
                var zoom = wheel.angleDelta.y / 120
                var tmpZoom = mapZoom;
                if(zoom > 0 && mapZoom != 19) {
                    mapZoom++;
                }
                if(zoom < 0 && mapZoom != 3) {
                    mapZoom--;
                }
                if(tmpZoom == mapZoom)
                    return;
                var zaCurrentPixelX = currentX * Math.pow(2, parseInt(mapZoom) - 18);
                var zaCurrentPixelY = currentY * Math.pow(2, parseInt(mapZoom) - 18);

                startPixelX = zaCurrentPixelX - wheel.x;
                startPixelY = zaCurrentPixelY + wheel.y;

                centerPixelX = startPixelX + (root.width / 2);
                centerPixelY = startPixelY - (root.height / 2);

                searchX = centerPixelX / Math.pow(2, parseInt(mapZoom) - 18);
                searchY = centerPixelY / Math.pow(2, parseInt(mapZoom) - 18);

                centerTileX = Math.abs(searchX * Math.pow(2, parseInt(mapZoom) - 18)) / 256;
                centerTileY = Math.abs(searchY * Math.pow(2, parseInt(mapZoom) - 18)) / 256;

                startX = startPixelX / Math.pow(2, parseInt(mapZoom) - 18);
                startY = startPixelY / Math.pow(2, parseInt(mapZoom) - 18);

                calcFourCorner();
            }
        }
    }

    //定时更新瓦片图的请求链接随机数，这里简单处理直接加一
    Timer {
        interval: 60000;
        running: true;
        repeat: true
        onTriggered: {
            randomNum++;
            if(randomNum == 4)
                randomNum = 0;
        }
    }

    Component.onCompleted: {
        searchX = 13375434.714050518;
        searchY = 3518517.0661275983;

        centerTileX = Math.abs(searchX * Math.pow(2, parseInt(mapZoom) - 18)) / 256;
        centerTileY = Math.abs(searchY * Math.pow(2, parseInt(mapZoom) - 18)) / 256;

        centerPixelX = Math.abs(searchX * Math.pow(2, parseInt(mapZoom) - 18));
        centerPixelY = Math.abs(searchY * Math.pow(2, parseInt(mapZoom) - 18));

        startPixelX = centerPixelX - Math.floor(root.width / 2);
        startPixelY = centerPixelY + Math.floor(root.height / 2);

        startX = startPixelX / Math.pow(2, parseInt(mapZoom) - 18);
        startY = startPixelY / Math.pow(2, parseInt(mapZoom) - 18);

        calcFourCorner();
    }

    function updateMapView() {
        for(var i = 0; i < repeater.model; i++) {
            var item = repeater.itemAt(i);
            if(item !== null)
                item.update();
        }
    }

    function calcFourCorner() {
        startPixelX = centerPixelX - Math.floor(root.width / 2);
        startPixelY = centerPixelY + Math.floor(root.height / 2);

        var endPixelX = startPixelX + root.width;
        var endPixelY = startPixelY - root.height;

        startX = startPixelX / Math.pow(2, parseInt(mapZoom) - 18);
        startY = startPixelY / Math.pow(2, parseInt(mapZoom) - 18);

        var endX = endPixelX / Math.pow(2, parseInt(mapZoom) - 18);
        var endY = endPixelY / Math.pow(2, parseInt(mapZoom) - 18);

        var leftTopLngLat = mercator2BD09(startX, startY);
        var rightBottomLngLat = mercator2BD09(endX, endY);

        leftTopLng = leftTopLngLat[0];
        leftTopLat = leftTopLngLat[1];
        rightBottomLng = rightBottomLngLat[0];
        rightBottomLat = rightBottomLngLat[1];

        updateMapView();
    }

    function initValues() {
        longitude = 0;
        latitude = 0;
        centerTileX = 0;
        centerTileY = 0;
        mapZoom = 15;
        searchX = 0;
        searchY = 0;
        startX = 0;
        startY = 0;
        startPixelX = 0;
        startPixelY = 0;
        centerPixelX = 0;
        centerPixelY = 0;
        mapX = 0;
        mapY = 0;
    }

    //将平面坐标转换为经纬度坐标
    function mercator2BD09(lng, lat) {
        var lnglat = [];
        var c;
        var d0 = [];
        var d0str = [ 1.410526172116255E-8, 8.98305509648872E-6, -1.9939833816331, 200.9824383106796, -187.2403703815547, 91.6087516669843, -23.38765649603339, 2.57121317296198, -0.03801003308653, 1.73379812E7 ];
        for (var i = 0; i < d0str.length; i++) {
            d0[i] = d0str[i];
        }
        var d1 = [];
        var d1str = [ -7.435856389565537E-9, 8.983055097726239E-6, -0.78625201886289, 96.32687599759846, -1.85204757529826, -59.36935905485877, 47.40033549296737, -16.50741931063887, 2.28786674699375, 1.026014486E7 ]
        for (var i = 0; i < d1str.length; i++) {
            d1[i] = d1str[i];
        }
        var d2 = [];
        var d2str = [ -3.030883460898826E-8, 8.98305509983578E-6, 0.30071316287616, 59.74293618442277, 7.357984074871, -25.38371002664745, 13.45380521110908, -3.29883767235584, 0.32710905363475, 6856817.37 ]
        for (var i = 0; i < d2str.length; i++) {
            d2[i] = d2str[i];
        }
        var d3 = [];
        var d3str = [ -1.981981304930552E-8, 8.983055099779535E-6, 0.03278182852591, 40.31678527705744, 0.65659298677277, -4.44255534477492, 0.85341911805263, 0.12923347998204, -0.04625736007561, 4482777.06 ];
        for (var i = 0; i < d3str.length; i++) {
            d3[i] = d3str[i];
        }
        var d4 = [];
        var d4str = [ 3.09191371068437E-9, 8.983055096812155E-6, 6.995724062E-5, 23.10934304144901, -2.3663490511E-4, -0.6321817810242, -0.00663494467273, 0.03430082397953, -0.00466043876332, 2555164.4 ];
        for (var i = 0; i < d4str.length; i++) {
            d4[i] = d4str[i];
        }
        var d5 = [];
        var d5str = [ 2.890871144776878E-9, 8.983055095805407E-6, -3.068298E-8, 7.47137025468032, -3.53937994E-6, -0.02145144861037, -1.234426596E-5, 1.0322952773E-4, -3.23890364E-6, 826088.5 ];
        for (var i = 0; i < d5str.length; i++) {
            d5[i] = d5str[i];
        }
        lnglat[0] = Math.abs(lng);
        lnglat[1] = Math.abs(lat);
        for (var d = 0; d < 6; d++) {
            if (lnglat[1] >= sp[d]) {
                if (d == 0) {
                    c = d0;
                }
                if (d == 1) {
                    c = d1;
                }
                if (d == 2) {
                    c = d2;
                }
                if (d == 3) {
                    c = d3;
                }
                if (d == 4) {
                    c = d4;
                }
                if (d == 5) {
                    c = d5;
                }
                break;
            }
        }
        lnglat = yr(lnglat, c);
        return lnglat;
    }

    function yr(lnglat, b) {
        if (typeof(b) != "undefined") {
            var c = parseFloat(b[0] + "") + parseFloat(b[1] + "") * Math.abs(lnglat[0]);
            var d = Math.abs(lnglat[1]) / parseFloat(b[9] + "");
            d = parseFloat(b[2] + "") + parseFloat(b[3] + "") * d + parseFloat(b[4] + "") * d * d + parseFloat(b[5] + "") * d * d * d + parseFloat(b[6] + "") * d * d * d * d + parseFloat(b[7] + "") * d * d * d * d * d + parseFloat(b[8] + "") * d * d * d * d * d * d;
            var bd;
            if (0 > lnglat[0]) {
                bd = -1 * c;
            }
            else {
                bd = c;
            }
            lnglat[0] = bd;
            var bd2;
            if (0 > lnglat[1]) {
                bd2 = -1 * d;
            }
            else {
                bd2 = d;
            }
            lnglat[1] = bd2;
            return lnglat;
        }
        return "null";
    }
}
