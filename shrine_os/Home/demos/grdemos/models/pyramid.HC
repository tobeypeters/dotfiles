#define MODEL_NAME "pyramid"

#define OBJ_POINTS 5
#define OBJ_EDGES 8

// Pyramid definition
CD3 pyramid_points[OBJ_POINTS] = {
    {0.0, 1.0, 0.0}, {-1.0, -1.0, -1.0}, {1.0, -1.0, -1.0},
    {1.0, -1.0, 1.0}, {-1.0, -1.0, 1.0}
};
CD2 pyramid_edges[OBJ_EDGES] = {
    {0,1},{0,2},{0,3},{0,4}, {1,2},{2,3},{3,4},{4,1}
};

CD3 *p_obj=&pyramid_points;
CD2 *v_obj=&pyramid_edges;
