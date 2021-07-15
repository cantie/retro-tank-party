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

void SGShape2D::_bind_methods() {
    // @todo?
}

SGRectangleShape2D::SGRectangleShape2D() {
    extents = Ref<SGFixedVector2>(memnew(SGFixedVector2));
}

SGRectangleShape2D::~SGRectangleShape2D() {
}

void SGRectangleShape2D::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_extents"), &SGRectangleShape2D::get_extents);
    ClassDB::bind_method(D_METHOD("set_extents", "extents"), &SGRectangleShape2D::set_extents);

	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "extents", PROPERTY_HINT_TYPE_STRING, "SGFixedVector2"), "set_extents", "get_extents");
}

void SGRectangleShape2D::set_extents(const Ref<SGFixedVector2>& p_extents) {
    extents = p_extents;
    emit_changed();
}

Ref<SGFixedVector2> SGRectangleShape2D::get_extents() {
    return extents;
}

void SGRectangleShape2D::draw(const RID &p_to_rid, const Color &p_color) {
    Size2 float_extents = extents->to_float();

	VisualServer::get_singleton()->canvas_item_add_rect(p_to_rid, Rect2(-float_extents, float_extents * 2.0), p_color);

    // Draw an outlined rectangle to make individual shapes easier to distinguish.
    Vector<Vector2> stroke_points;
    stroke_points.resize(5);
    stroke_points.write[0] = -float_extents;
    stroke_points.write[1] = Vector2(float_extents.x, -float_extents.y);
    stroke_points.write[2] = float_extents;
    stroke_points.write[3] = Vector2(-float_extents.x, float_extents.y);
    stroke_points.write[4] = -float_extents;

    Vector<Color> stroke_colors;
    stroke_colors.resize(5);
    for (int i = 0; i < 5; i++) {
        stroke_colors.write[i] = p_color;
    }

    VisualServer::get_singleton()->canvas_item_add_polyline(p_to_rid, stroke_points, stroke_colors, 1.0, true);
}
