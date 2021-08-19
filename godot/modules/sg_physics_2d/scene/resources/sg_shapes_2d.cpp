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

#include "sg_shapes_2d.h"

#include <servers/visual_server.h>

#include "../../internal/sg_shapes_2d_internal.h"

void SGShape2D::_bind_methods() {
}

SGShape2D::SGShape2D(SGShape2DInternal *p_shape) {
    shape = p_shape;
}

SGShape2D::~SGShape2D() {
    if (shape) {
        memdelete(shape);
    }
}

void SGRectangleShape2D::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_extents"), &SGRectangleShape2D::get_extents);
    ClassDB::bind_method(D_METHOD("set_extents", "extents"), &SGRectangleShape2D::set_extents);

	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "extents", PROPERTY_HINT_TYPE_STRING, "SGFixedVector2"), "set_extents", "get_extents");
}

void SGRectangleShape2D::set_extents(const Ref<SGFixedVector2>& p_extents) {
    extents->set_internal(p_extents->get_internal());
    _change_notify("extents");
    emit_changed();
}

Ref<SGFixedVector2> SGRectangleShape2D::get_extents() {
    return extents;
}

void SGRectangleShape2D::sync_to_physics_engine(const fixed_transform2d &p_transform) const {
    SGRectangle2DInternal* internal = (SGRectangle2DInternal *)get_shape_internal();
    internal->set_transform(p_transform);
    internal->set_extents(extents->get_internal());
}

void SGRectangleShape2D::draw(const RID &p_to_rid, const Color &p_color) {
    Size2 float_extents = extents->to_float();

	VisualServer::get_singleton()->canvas_item_add_rect(p_to_rid, Rect2(-float_extents, float_extents * 2.0), p_color);
}

SGRectangleShape2D::SGRectangleShape2D() :
    SGShape2D(memnew(SGRectangle2DInternal(fixed(655360), fixed(655360)))),
    extents(Ref<SGFixedVector2>(memnew(SGFixedVector2(fixed_vector2(fixed(655360), fixed(655360))))))
{
    extents->connect("changed", this, "emit_changed");
}

SGRectangleShape2D::~SGRectangleShape2D() {
}


void SGCircleShape2D::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_radius"), &SGCircleShape2D::get_radius);
    ClassDB::bind_method(D_METHOD("set_radius", "radius"), &SGCircleShape2D::set_radius);

	ADD_PROPERTY(PropertyInfo(Variant::INT, "radius"), "set_radius", "get_radius");
}

void SGCircleShape2D::set_radius(int p_radius) {
    radius = fixed(p_radius);
    _change_notify("extents");
    emit_changed();
}

int SGCircleShape2D::get_radius() const {
    return radius.value;
}

void SGCircleShape2D::sync_to_physics_engine(const fixed_transform2d &p_transform) const {
    SGCircle2DInternal* internal = (SGCircle2DInternal *)get_shape_internal();
    internal->set_transform(p_transform);
    internal->set_radius(fixed(radius));
}

void SGCircleShape2D::draw(const RID &p_to_rid, const Color &p_color) {
    float float_radius = radius.to_float();

	Vector<Vector2> points;
	for (int i = 0; i < 24; i++) {

		points.push_back(Vector2(Math::cos(i * Math_PI * 2 / 24.0), Math::sin(i * Math_PI * 2 / 24.0)) * float_radius);
	}

	Vector<Color> col;
	col.push_back(p_color);
	VisualServer::get_singleton()->canvas_item_add_polygon(p_to_rid, points, col);
}

SGCircleShape2D::SGCircleShape2D() :
    SGShape2D(memnew(SGCircle2DInternal(fixed(655360)))),
    radius(655360)
{
}

SGCircleShape2D::~SGCircleShape2D() {
}
