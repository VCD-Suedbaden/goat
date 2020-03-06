DROP FUNCTION IF EXISTS PropagateInsert;
CREATE FUNCTION PropagateInsert(poi_id int) RETURNS void AS
$BODY$
DECLARE
	insert_buffer geometry;
	network_chunk_query TEXT;
BEGIN
	
	insert_buffer =
		st_buffer(geom, 0.01)
		FROM pois_userinput
		WHERE gid = poi_id;
	
	UPDATE grid_500 SET dirty = TRUE
   	WHERE st_contains(insert_buffer, grid_500.geom);   
   
	-- TODO: Max snapping distance
	DROP TABLE IF EXISTS source_target_nodes;
	CREATE TABLE source_target_nodes AS (
		SELECT source_nodes.id AS source_nodes, grid_id AS source_ids, target_node.id AS target_node, poi_id AS target_id
   		FROM (
			SELECT id, pois_userinput.gid FROM ways_vertices_pgr, pois_userinput ORDER BY ways_vertices_pgr.geom
			<->
    		(select geom from pois_userinput where gid = poi_id)
			LIMIT 1 
		) AS target_node	
		CROSS JOIN (
			SELECT grid_id, vertices.id
			FROM grid_500 g
			CROSS JOIN LATERAL
	  		(
	  			SELECT geom, id
	   			FROM ways_vertices_pgr w
				WHERE w.geom && ST_Buffer(g.centroid,0.001) AND g.dirty = TRUE
	   			ORDER BY
	    		g.centroid <-> w.geom
	   			LIMIT 1
	   		) AS vertices
		) AS source_nodes
	);

	network_chunk_query = fetch_ways_routing_text(st_astext(st_buffer(insert_buffer, 1)), 1, 1, 'walking_standard');
	
	WITH routes AS (
		SELECT (pgr_astar(network_chunk_query, source_nodes::int4, target_node::int4, FALSE, FALSE)).cost, source_nodes, target_node, source_ids, target_id
		FROM source_target_nodes
	)
	--TODO: update cost on conflict
	INSERT INTO reached_points (cost, cell_id, object_id, user_id, scenario, routing_method)
	SELECT sum(cost) AS cost, source_ids AS cell_id, target_id AS object_id, 1 AS user_id, 1 AS scenario, 'walking_standard' AS routing_method
	FROM routes
	GROUP BY source_nodes, source_ids, target_id;
																--TODO: factor in amenity
   	UPDATE reached_points SET cost_sensitivity = SensitivityFunction(cost, amenity_alpha_weights.alpha), weight = amenity_alpha_weights.weight
   	FROM grid_500, amenity_alpha_weights, pois_userinput
    WHERE grid_id = reached_points.cell_id AND dirty = TRUE AND amenity_alpha_weights.amenity = pois_userinput.amenity AND object_id = gid;
																--TODO: factor in amenity
   	UPDATE reached_points SET weighted_by_amenity = cost_sensitivity * weight
    WHERE object_id = poi_id;
	
   
   
    UPDATE grid_500 SET poi_walkability_index = sum
	FROM (	
		SELECT sum(weighted_by_amenity), cell_id
		FROM reached_points, grid_500
		WHERE grid_id = cell_id AND dirty = TRUE
		GROUP BY cell_id
	) AS sum_per_cells
	WHERE cell_id = grid_id;
   
   
    --UPDATE grid_500 SET poi_walkability_index = sum(weighted_by_amenity)
    --FROM reached_points
    --WHERE grid_id = cell_id AND dirty = TRUE;
	UPDATE grid_500 SET dirty = FALSE
	WHERE dirty = TRUE;

    return;
END;
$BODY$ LANGUAGE plpgsql;


----------------------------------------------------------------------------
SELECT PropagateInsert(3255)

DELETE FROM reached_points;
UPDATE grid_500 SET dirty = FALSE;
UPDATE grid_500 SET poi_walkability_index = NULL;
  
SELECT grid_id, poi_walkability_index
FROM grid_500
WHERE poi_walkability_index IS NOT NULL
ORDER BY poi_walkability_index DESC


SELECT gid, pois_userinput.amenity
FROM pois_userinput, amenity_alpha_weights
WHERE pois_userinput.amenity = amenity_alpha_weights.amenity


WITH txt AS (
	SELECT fetch_ways_routing(st_astext(st_buffer(geom, 1)), 1, 1, 'walking_standard')
	FROM pois
	WHERE gid = 225
),
routes AS (
	SELECT (pgr_astar(txt.fetch_ways_routing_text, source_nodes::int4, target_node::int4, FALSE, FALSE)).cost, source_nodes, target_node, source_ids, target_id
	FROM txt, source_target_nodes
)

SELECT sum(cost) AS cost, source_ids AS cell_id, target_id AS object_id
FROM routes
GROUP BY source_nodes, source_ids, target_id

SELECT  pgr_costresult.cost FROM  pgr_costresult;



select fetch_ways_routing_text(ST_ASTEXT(ST_BUFFER(ST_POINT(11.543274,48.195524),0.01)),1,1,'walking_standard');
DROP TABLE IF EXISTS chunk;



CREATE TABLE chunk AS
SELECT id::integer, source, target,length_m as cost, length_m as reverse_cost,slope_profile,death_end, st_x(st_startpoint(geom)) AS x1, st_y(st_startpoint(geom)) AS y1, st_x(st_endpoint(geom)) AS x2, st_y(st_endpoint(geom)) AS y2, geom  
		FROM ways WHERE NOT class_id = ANY('{0,101,102,103,104,105,106,107,501,502,503,504,701,801}')
    	AND (NOT foot = ANY('{use_sidepath,no}') 
		OR foot IS NULL)
		 AND geom && ST_GeomFromText('POLYGON((11.2465718 48.1724684,11.246379652804 48.1705174967798,11.2458105953251 48.1686415656763,11.244886496123 48.1669126976698,11.2436428678119 48.1653973321881,11.2421275023302 48.164153703877,11.2403986343237 48.1632296046749,11.2385227032202 48.162660547196,11.2365718 48.1624684,11.2346208967798 48.162660547196,11.2327449656763 48.1632296046749,11.2310160976698 48.164153703877,11.2295007321881 48.1653973321881,11.228257103877 48.1669126976698,11.2273330046749 48.1686415656763,11.226763947196 48.1705174967798,11.2265718 48.1724684,11.226763947196 48.1744193032202,11.2273330046749 48.1762952343237,11.228257103877 48.1780241023302,11.2295007321881 48.1795394678119,11.2310160976698 48.180783096123,11.2327449656763 48.1817071953251,11.2346208967798 48.182276252804,11.2365718 48.1824684,11.2385227032202 48.182276252804,11.2403986343237 48.1817071953251,11.2421275023302 48.180783096123,11.2436428678119 48.1795394678119,11.244886496123 48.1780241023302,11.2458105953251 48.1762952343237,11.246379652804 48.1744193032202,11.2465718 48.1724684))')



CREATE TABLE _txt AS
	SELECT fetch_ways_routing_text(st_astext(st_buffer(geom, 0.01)), 1, 1, 'walking_standard')
	FROM pois
	WHERE gid = 225

EXECUTE txt.fetch_ways_routing_text


	SELECT fetch_ways_routing_text(st_astext(st_buffer(geom, 0.01)), 1, 1, 'walking_standard')
	FROM pois
	WHERE gid = 225

	
	
	
	
