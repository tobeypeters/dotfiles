#define MODEL_NAME "cube.HC"

#define OBJ_POINTS 8
#define OBJ_EDGES 12

//Cube definition
CD3 cube_points[OBJ_POINTS] = {
    {-1.0, 1.0, -1.0}, {1.0, 1.0, -1.0}, {1.0, -1.0, -1.0}, {-1.0, -1.0, -1.0},
    {-1.0, 1.0, 1.0},  {1.0, 1.0, 1.0},  {1.0, -1.0, 1.0},  {-1.0, -1.0, 1.0}
};
CD2 cube_edges[OBJ_EDGES] = {
    {0,1},{1,2},{2,3},{3,0}, {4,5},{5,6},{6,7},{7,4}, {0,4},{1,5},{2,6},{3,7}
};

CD3 *p_obj=&cube_points;
CD2 *v_obj=&cube_edges;
