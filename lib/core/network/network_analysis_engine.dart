import 'dart:math' as math;
import '../models/survivor_record.dart';
import '../models/network_link.dart';

// NetworkAnalysisEngine implements mathematical graph algorithms (BFS, DFS, Tarjan's)
// to analyze smartphone ad-hoc network topologies (SPAN).
class NetworkAnalysisEngine {
  
  // Builds the adjacency list mapping node ID -> list of neighbor node IDs
  static Map<String, List<String>> buildAdjacencyList(
    List<SurvivorRecord> survivors,
    List<NetworkLink> links,
  ) {
    final Map<String, List<String>> adj = {};
    
    // Initialize empty lists for all known nodes
    for (var s in survivors) {
      adj[s.id] = [];
    }

    // Populate active links bidirectionally
    for (var link in links) {
      if (adj.containsKey(link.sourceId) && adj.containsKey(link.targetId)) {
        if (!adj[link.sourceId]!.contains(link.targetId)) {
          adj[link.sourceId]!.add(link.targetId);
        }
        if (!adj[link.targetId]!.contains(link.sourceId)) {
          adj[link.targetId]!.add(link.sourceId);
        }
      }
    }

    return adj;
  }

  // Finds all connected components (sub-graphs) in the network
  static List<List<String>> findConnectedComponents(
    List<String> nodes,
    Map<String, List<String>> adj,
  ) {
    final List<List<String>> components = [];
    final Set<String> visited = {};

    for (var node in nodes) {
      if (!visited.contains(node)) {
        final List<String> component = [];
        final List<String> queue = [node];
        visited.add(node);

        int head = 0;
        while (head < queue.length) {
          final current = queue[head++];
          component.add(current);

          for (var neighbor in adj[current] ?? []) {
            if (!visited.contains(neighbor)) {
              visited.add(neighbor);
              queue.add(neighbor);
            }
          }
        }
        components.add(component);
      }
    }

    return components;
  }

  // A. Finds the topological centroid (medoid) of a connected component.
  // The medoid minimizes the average multi-hop hop-count to all other nodes in the same component.
  static String findTopologicalCentroid(
    List<String> component,
    Map<String, List<String>> adj,
  ) {
    if (component.isEmpty) return '';
    if (component.length == 1) return component.first;

    String bestCentroid = component.first;
    double minAvgDistance = double.infinity;

    for (var root in component) {
      // Run Breadth-First Search (BFS) to find hop distances from 'root'
      final Map<String, int> distances = {};
      final List<String> queue = [root];
      distances[root] = 0;

      int head = 0;
      while (head < queue.length) {
        final current = queue[head++];
        final currentDist = distances[current]!;

        for (var neighbor in adj[current] ?? []) {
          if (!distances.containsKey(neighbor)) {
            distances[neighbor] = currentDist + 1;
            queue.add(neighbor);
          }
        }
      }

      // Sum path hop lengths
      int sumHops = 0;
      int reachedCount = 0;
      for (var node in component) {
        if (distances.containsKey(node)) {
          sumHops += distances[node]!;
          reachedCount++;
        }
      }

      // Average topological hop distance
      double avgHops = reachedCount > 1 ? sumHops / (reachedCount - 1) : 0.0;
      
      // We prioritize roots that reach the maximum number of component nodes,
      // and then choose the one that minimizes the average distance.
      if (reachedCount == component.length && avgHops < minAvgDistance) {
        minAvgDistance = avgHops;
        bestCentroid = root;
      }
    }

    return bestCentroid;
  }

  // B. Tarjan's Algorithm to find all cut-vertices / Articulation Points.
  // Returns a set of node IDs representing the critical communication bridges.
  static Set<String> findArticulationPoints(
    List<String> nodes,
    Map<String, List<String>> adj,
  ) {
    final Set<String> articulationPoints = {};
    final Map<String, int> tin = {}; // Discovery time
    final Map<String, int> low = {}; // Lowest discovery time reachable
    final Map<String, String?> parent = {};
    final Set<String> visited = {};
    int timer = 0;

    void dfs(String u) {
      visited.add(u);
      tin[u] = low[u] = ++timer;
      int children = 0;

      for (var v in adj[u] ?? []) {
        if (v == parent[u]) continue;

        if (visited.contains(v)) {
          // Back-edge
          low[u] = math.min(low[u]!, tin[v]!);
        } else {
          // Forward-edge in DFS tree
          parent[v] = u;
          children++;
          dfs(v);

          low[u] = math.min(low[u]!, low[v]!);

          // Condition 1: Non-root node is an articulation point if low[v] >= tin[u]
          if (parent[u] != null && low[v]! >= tin[u]!) {
            articulationPoints.add(u);
          }
        }
      }

      // Condition 2: Root node is an articulation point if it has 2 or more children in DFS tree
      if (parent[u] == null && children > 1) {
        articulationPoints.add(u);
      }
    }

    for (var node in nodes) {
      if (!visited.contains(node)) {
        parent[node] = null;
        dfs(node);
      }
    }

    return articulationPoints;
  }

  // C. Aggregates the needs of all active (non-safe) survivors in a connected component.
  static Map<String, int> aggregateComponentNeeds(
    List<String> component,
    List<SurvivorRecord> survivors,
  ) {
    final Map<String, int> demand = {};

    for (var nodeId in component) {
      final survivor = survivors.firstWhere(
        (s) => s.id == nodeId,
        orElse: () => SurvivorRecord(
          id: nodeId,
          name: 'Unknown',
          latitude: 0.0,
          longitude: 0.0,
          status: SurvivorStatus.safe,
          needs: '',
          timestamp: 0,
          sequenceNumber: 0,
          batteryPercentage: 0,
          message: '',
        ),
      );
      if (survivor.status == SurvivorStatus.safe) continue; // Skip safe nodes

      if (survivor.needs.isNotEmpty) {
        final needsList = survivor.needs.split(', ').map((e) => e.trim()).where((e) => e.isNotEmpty);
        for (var need in needsList) {
          demand[need] = (demand[need] ?? 0) + 1;
        }
      }
    }

    return demand;
  }
}
