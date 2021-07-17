/*************************************************************************/
/* Copyright (c) 2021 David Snopek                                       */
/*                                                                       */
/* Permission is hereby granted, free of charge, to any person obtaining */
/* a copy of this software and associated documentation files (the       */
/* "Software"), to deal in the Software without restriction, including   */
/* without limitation the rights to use, copy, modify, merge, publish,   */
/* distribute, sublicense, and/or sell copies of the Software, and to    */
/* permit persons to whom the Software is furnished to do so, subject to */
/* the following conditions:                                             */
/*                                                                       */
/* The above copyright notice and this permission notice shall be        */
/* included in all copies or substantial portions of the Software.       */
/*                                                                       */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF    */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.*/
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY  */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,  */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE     */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                */
/*************************************************************************/

#include "sg_physics_2d_server.h"

SGPhysics2DServer *SGPhysics2DServer::singleton = nullptr;

SGPhysics2DServer::SGPhysics2DServer() {
	ERR_FAIL_COND(singleton != NULL);
	singleton = this;
}

SGPhysics2DServer::~SGPhysics2DServer() {
	singleton = NULL;
}

SGPhysics2DServer *SGPhysics2DServer::get_singleton() {
	return singleton;
}

void SGPhysics2DServer::_bind_methods() {
    ClassDB::bind_method(D_METHOD("create_rectangle_shape", "x", "y", "w", "h"), &SGPhysics2DServer::create_rectangle_shape);
    ClassDB::bind_method(D_METHOD("shape_overlaps", "shape_one", "shape_two"), &SGPhysics2DServer::shape_overlaps);
}

RID SGPhysics2DServer::create_area() {
    SGArea2DInternal *area = memnew(SGArea2DInternal);
    temp_areas.push_back(area);
    RID id = area_owner.make_rid(area);
    return id;
}

RID SGPhysics2DServer::create_rectangle_shape(int x, int y, int w, int h) {
    SGRectangle2DInternal *rectangle = memnew(SGRectangle2DInternal);
    rectangle->set_position(fixed_vector2(fixed(x), fixed(y)));
    rectangle->set_extents(fixed_vector2(fixed(w), fixed(h)));

    RID id = shape_owner.make_rid(rectangle);
	return id;
}

void SGPhysics2DServer::area_add_shape(RID p_area, RID p_shape) {
    SGArea2DInternal *area = static_cast<SGArea2DInternal *>(p_area.get_data());
    SGShape2DInternal *shape = static_cast<SGShape2DInternal *>(p_shape.get_data());

    area->add_shape(shape);
}



/*
bool SGPhysics2DServer::shape_overlaps(RID p_shape_one, RID p_shape_two) {

    SGRectangle2DInternal *rect1 = static_cast<SGRectangle2DInternal *>(p_shape_one.get_data());
    SGRectangle2DInternal *rect2 = static_cast<SGRectangle2DInternal *>(p_shape_two.get_data());

    fixed_vector2 min_one = rect1->get_bounds().get_min();
    fixed_vector2 max_one = rect1->get_bounds().get_max();
    fixed_vector2 min_two = rect2->get_bounds().get_min();
    fixed_vector2 max_two = rect2->get_bounds().get_max();

    return (min_two.x <= max_one.x) && (min_one.x <= max_two.x) && \
           (min_two.y <= max_one.y) && (min_one.y <= max_two.y);
}
*/
