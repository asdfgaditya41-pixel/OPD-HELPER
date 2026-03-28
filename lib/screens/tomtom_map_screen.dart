import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/hospital.dart';
import 'hospital_detail_screen.dart';

class TomTomMapScreen extends StatefulWidget {
  final List<Hospital> hospitals;
  final double? userLat;
  final double? userLng;
  final bool hideAppBar;
  final String? bestHospitalId;

  const TomTomMapScreen({
    super.key,
    required this.hospitals,
    this.userLat,
    this.userLng,
    this.hideAppBar = false,
    this.bestHospitalId,
  });

  @override
  State<TomTomMapScreen> createState() => _TomTomMapScreenState();
}

class _TomTomMapScreenState extends State<TomTomMapScreen> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'HospitalChannel',
        onMessageReceived: (message) {
          if (!mounted) return;
          final id = message.message.trim();
          Hospital? hospital;
          try {
            hospital = widget.hospitals.firstWhere((h) => h.id == id);
          } catch (_) {
            hospital = null;
          }
          if (hospital != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HospitalDetailScreen(hospital: hospital!),
              ),
            );
          }
        },
      )
      ..loadHtmlString(_htmlContent());
  }

  @override
  void didUpdateWidget(covariant TomTomMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    String oldIds = oldWidget.hospitals.map((h) => h.id).join(',');
    String newIds = widget.hospitals.map((h) => h.id).join(',');
    
    // Only reload the HTML if the actual set of hospitals changes (like switching cities)
    // or if the user's location overlay changes. (Prevents flashing map during queue updates)
    if (oldIds != newIds || widget.userLat != oldWidget.userLat || widget.userLng != oldWidget.userLng) {
      controller.loadHtmlString(_htmlContent());
    }
  }

  String _htmlContent() {
    String hospitalJS = widget.hospitals.map((h) {
      return """
      {
        id: "${h.id}",
        name: "${h.name}",
        lat: ${h.lat},
        lng: ${h.lng},
        queue: ${h.opdQueue},
        waitTime: ${h.waitTime},
        beds: ${h.bedsAvailable},
        type: "${h.type}"
      }
      """;
    }).join(",");

    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <script src="https://api.tomtom.com/maps-sdk-for-web/cdn/6.x/6.20.0/maps/maps-web.min.js"></script>
      <link href="https://api.tomtom.com/maps-sdk-for-web/cdn/6.x/6.20.0/maps/maps.css" rel="stylesheet" />
      <style>
        body, html { margin:0; padding:0; height:100%; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
        #map { width:100%; height:100%; }

        /* ETA card */
        #eta-card {
            position: absolute;
            bottom: 130px;
            left: 50%;
            transform: translateX(-50%);
            background: linear-gradient(135deg, rgba(0, 191, 165, 0.92), rgba(0, 137, 123, 0.92));
            color: #fff;
            padding: 12px 24px;
            border-radius: 22px;
            box-shadow: 0 8px 32px rgba(0,191,165,0.25), 0 4px 12px rgba(0,0,0,0.3);
            display: none;
            z-index: 1000;
            font-size: 15px;
            font-weight: 700;
            letter-spacing: 0.5px;
            border: 1px solid rgba(255,255,255,0.15);
            white-space: nowrap;
        }

        /* Hospital info card (slides up from bottom) */
        #info-card {
            position: absolute;
            bottom: -160px;
            left: 16px;
            right: 16px;
            background: rgba(10, 26, 32, 0.95);
            border: 1px solid rgba(0, 191, 165, 0.3);
            border-radius: 20px;
            padding: 16px 18px;
            z-index: 1001;
            box-shadow: 0 -4px 30px rgba(0,0,0,0.4);
            transition: bottom 0.35s cubic-bezier(0.34, 1.56, 0.64, 1);
        }
        #info-card.visible { bottom: 115px; }
        #info-card h3 {
            margin: 0 0 8px 0;
            font-size: 16px;
            font-weight: 700;
            color: #fff;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        .info-row {
            display: flex;
            gap: 8px;
            margin-bottom: 12px;
        }
        .badge {
            background: rgba(255,255,255,0.07);
            border: 1px solid rgba(255,255,255,0.1);
            border-radius: 10px;
            padding: 6px 12px;
            font-size: 12px;
            color: rgba(255,255,255,0.8);
            flex: 1;
            text-align: center;
        }
        .badge span {
            display: block;
            font-size: 15px;
            font-weight: 700;
            color: #fff;
            margin-bottom: 2px;
        }
        #btn-details {
            width: 100%;
            padding: 13px;
            background: linear-gradient(135deg, #00BFA5, #00897B);
            color: white;
            border: none;
            border-radius: 14px;
            font-size: 15px;
            font-weight: 700;
            letter-spacing: 0.5px;
            cursor: pointer;
            box-shadow: 0 4px 16px rgba(0,191,165,0.35);
        }
        #btn-close {
            position: absolute;
            top: 12px; right: 14px;
            background: rgba(255,255,255,0.08);
            border: none;
            color: rgba(255,255,255,0.5);
            border-radius: 50%;
            width: 28px; height: 28px;
            font-size: 16px;
            cursor: pointer;
            display: flex; align-items: center; justify-content: center;
        }
      </style>
    </head>
    <body>
      <div id="map"></div>
      <div id="eta-card"></div>
      <div id="info-card">
        <button id="btn-close" onclick="closeCard()">✕</button>
        <h3 id="card-name"></h3>
        <div class="info-row">
          <div class="badge"><span id="card-queue">—</span>Queue</div>
          <div class="badge"><span id="card-wait">—</span>Wait</div>
          <div class="badge"><span id="card-beds">—</span>Beds</div>
        </div>
        <button id="btn-details">🏥 View Full Details</button>
      </div>

      <script>
        var map = tt.map({
          key: 'xgHnapO3jqZBMNLOxLeJuRVxzlHA7bBa',
          container: 'map',
          center: [${widget.userLng ?? 77.2090}, ${widget.userLat ?? 28.6139}],
          zoom: 12
        });

        var hospitals = [$hospitalJS];
        var bounds = new tt.LngLatBounds();
        var hasMarkers = false;

        // 🔵 USER LOCATION
        ${widget.userLat != null ? '''
        var userMarker = new tt.Marker({color: "blue"})
          .setLngLat([${widget.userLng}, ${widget.userLat}])
          .addTo(map);
        bounds.extend([${widget.userLng}, ${widget.userLat}]);
        hasMarkers = true;
        ''' : ''}

        hospitals.forEach(h => {
          hasMarkers = true;
          bounds.extend([h.lng, h.lat]);

          var markerColor = h.type === 'government' ? '#4caf50' : '#2196f3';

          var isBest = h.id === '${widget.bestHospitalId}';
          var symbol = isBest ? "⭐" : "🏥";
          var border = isBest ? "3px solid gold" : "3px solid white";

          var el = document.createElement('div');
          el.style.width = isBest ? '42px' : '36px';
          el.style.height = isBest ? '42px' : '36px';
          el.style.backgroundColor = markerColor;
          el.style.borderRadius = '50%';
          el.style.border = border;
          el.style.boxShadow = isBest ? '0 0 15px gold' : '0 4px 10px rgba(0,0,0,0.3)';
          el.style.display = 'flex';
          el.style.alignItems = 'center';
          el.style.justifyContent = 'center';
          el.style.color = 'white';
          el.style.fontWeight = 'bold';
          el.style.fontSize = isBest ? '20px' : '16px';
          el.innerHTML = symbol;
          var marker = new tt.Marker({element: el})
            .setLngLat([h.lng, h.lat])
            .addTo(map);

          // Click marker → show custom info card + draw route
          (function(hospital) {
            el.addEventListener('click', function(e) {
              e.stopPropagation();
              showCard(hospital);
              calculateAndDrawRoute(hospital);
            });
          })(h);

          // 🚀 ROUTE FUNCTION
          function calculateAndDrawRoute(hospital) {
            ${widget.userLat != null ? '''
            fetch(
              "https://api.tomtom.com/routing/1/calculateRoute/" +
              "${widget.userLat},${widget.userLng}:" +
              hospital.lat + "," + hospital.lng +
              "/json?key=xgHnapO3jqZBMNLOxLeJuRVxzlHA7bBa"
            )
            .then(res => res.json())
            .then(data => {
              var points = data.routes[0].legs[0].points;
              var route = points.map(p => [p.longitude, p.latitude]);
              if (map.getLayer('route')) { map.removeLayer('route'); map.removeSource('route'); }
              map.addLayer({
                id: 'route', type: 'line',
                source: { type: 'geojson', data: { type: 'Feature', geometry: { type: 'LineString', coordinates: route } } },
                paint: { 'line-color': '#00BFA5', 'line-width': 5 }
              });
              var routeBounds = new tt.LngLatBounds();
              route.forEach(function(point) { routeBounds.extend(point); });
              map.fitBounds(routeBounds, { padding: 80 });
              var summary = data.routes[0].summary;
              var mins = Math.round(summary.travelTimeInSeconds / 60);
              var dist = (summary.lengthInMeters / 1000).toFixed(1);
              var etaCard = document.getElementById('eta-card');
              etaCard.innerHTML = "🚗 " + mins + " min • " + dist + " km";
              etaCard.style.display = "block";
            });
            ''' : ''}
          }

        });

        // -------------------------------------------------------------------
        // 🏥 HOSPITAL INFO CARD LOGIC
        // -------------------------------------------------------------------
        var currentHospitalId = null;

        function showCard(hospital) {
            currentHospitalId = hospital.id;
            document.getElementById('card-name').innerText = hospital.name;
            document.getElementById('card-queue').innerText = hospital.queue;
            document.getElementById('card-wait').innerText = hospital.waitTime + 'm';
            document.getElementById('card-beds').innerText = hospital.beds;
            document.getElementById('info-card').classList.add('visible');
        }

        function closeCard() {
            document.getElementById('info-card').classList.remove('visible');
            document.getElementById('eta-card').style.display = 'none';
            if (map.getLayer('route')) {
                map.removeLayer('route');
                map.removeSource('route');
            }
            currentHospitalId = null;
        }

        document.getElementById('btn-details').addEventListener('click', function() {
            if (currentHospitalId && window.HospitalChannel) {
                window.HospitalChannel.postMessage(currentHospitalId);
            }
        });

        // Close card if map is clicked
        map.on('click', function() {
            closeCard();
        });

        if (hasMarkers) {
           map.fitBounds(bounds, { padding: 50 });
        }
      </script>
    </body>
    </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hideAppBar) {
      return Scaffold(
        body: SafeArea(child: WebViewWidget(controller: controller)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text("TomTom Map")),
      body: WebViewWidget(controller: controller),
    );
  }
}

