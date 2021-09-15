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

#include "sg_collision_polygon_2d.h"

#include <core/engine.h>
#include "sg_collision_object_2d.h"

void SGCollisionPolygon2D::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_polygon", "polygon"), &SGCollisionPolygon2D::set_polygon);
	ClassDB::bind_method(D_METHOD("get_polygon"), &SGCollisionPolygon2D::get_polygon);

	ClassDB::bind_method(D_METHOD("set_fixed_polygon", "polygon"), &SGCollisionPolygon2D::set_fixed_polygon);
	ClassDB::bind_method(D_METHOD("get_fixed_polygon"), &SGCollisionPolygon2D::get_fixed_polygon);

	ADD_PROPERTY(PropertyInfo(Variant::POOL_VECTOR2_ARRAY, "polygon", PROPERTY_HINT_NONE, "", 0), "set_polygon", "get_polygon");
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "fixed_polygon"), "set_fixed_polygon", "get_fixed_polygon");
}

void SGCollisionPolygon2D::_notification(int p_what) {
    switch (p_what) {
        case NOTIFICATION_DRAW: {
            if (!Engine::get_singleton()->is_editor_hint() && !get_tree()->is_debugging_collisions_hint()) {
                break;
            }

			if (fixed_polygon.size() == 0) {
				break;
			}

			if (polygon.size() == 0) {
				update_polygon();
			}

			int polygon_count = polygon.size();
			for (int i = 0; i < polygon_count; i++) {
				Vector2 p = polygon[i];
				Vector2 n = polygon[(i + 1) % polygon_count];
				// draw line with width <= 1, so it does not scale with zoom and break pixel exact editing
				draw_line(p, n, Color(0.9, 0.2, 0.0, 0.8), 1);
			}

			if (polygon_count > 2) {
				draw_colored_polygon(polygon, get_tree()->get_debug_collisions_color());
			}
		} break;
        
        case NOTIFICATION_PARENTED:
            collision_object = Object::cast_to<SGCollisionObject2D>(get_parent());
            if (collision_object && !disabled) {
                collision_object->add_shape(internal_shape);
            }
            break;
        
        case NOTIFICATION_UNPARENTED:
            if (collision_object && !disabled) {
                collision_object->remove_shape(internal_shape);
            }
            collision_object = nullptr;
            break;

    }

}

void SGCollisionPolygon2D::update_polygon() const {
	polygon.clear();
	polygon.resize(fixed_polygon.size());

	for (int i = 0; i < fixed_polygon.size(); i++) {
		Ref<SGFixedVector2> p = fixed_polygon.get(i);
		if (p.is_valid()) {
			polygon.write[i] = p->to_float();
		}
	}

	update_aabb();
}

void SGCollisionPolygon2D::update_aabb() const {
	aabb = Rect2();
	for (int i = 0; i < polygon.size(); i++) {
		if (i == 0) {
			aabb = Rect2(polygon[i], Size2());
		}
		else {
			aabb.expand_to(polygon[i]);
		}
	}

	if (aabb == Rect2()) {
		aabb = Rect2(-10, -10, 20, 20);
	} else {
		aabb.position -= aabb.size * 0.3;
		aabb.size += aabb.size * 0.6;
	}
}

void SGCollisionPolygon2D::update_fixed_polygon() {
	fixed_polygon.clear();
	fixed_polygon.resize(polygon.size());

	for (int i = 0; i < polygon.size(); i++) {
		Ref<SGFixedVector2> p(memnew(SGFixedVector2));
		p->from_float(polygon[i]);
		fixed_polygon[i] = p;
	}

	update_internal_shape();

	_change_notify("fixed_polygon");
}

#ifdef TOOLS_ENABLED
Rect2 SGCollisionPolygon2D::_edit_get_rect() const {
	return aabb;
}

bool SGCollisionPolygon2D::_edit_use_rect() const {
	return true;
}

bool SGCollisionPolygon2D::_edit_is_selected_on_click(const Point2 &p_point, double p_tolerance) const {
	return Geometry::is_point_in_polygon(p_point, Variant(polygon));
}
#endif

void SGCollisionPolygon2D::set_disabled(bool p_disabled) {
    if (disabled != p_disabled) {
        disabled = p_disabled;
        if (collision_object) {
            if (disabled) {
                collision_object->remove_shape(internal_shape);
            }
            else {
                collision_object->add_shape(internal_shape);
            }
        }
    }
}

bool SGCollisionPolygon2D::get_disabled() const {
	return disabled;
}

void SGCollisionPolygon2D::set_polygon(const Vector<Point2> &p_polygon) {
	polygon = p_polygon;
	update_fixed_polygon();
	update_aabb();

	update();
	update_configuration_warning();
}

Vector<Point2> SGCollisionPolygon2D::get_polygon() const {
	if (fixed_polygon.size() > 0 && polygon.size() == 0) {
		update_polygon();
	}
	return polygon;
}

void SGCollisionPolygon2D::set_fixed_polygon(const Array &p_fixed_polygon) {
	// Should we really be copying the vectors?
	fixed_polygon = p_fixed_polygon;

	// If polygon is empty, then we don't bother regenerating it, since it's
	// not needed at runtime at all.
	if (polygon.size() > 0) {
		update_polygon();
	}

	update_internal_shape();
}

Array SGCollisionPolygon2D::get_fixed_polygon() const {
	return fixed_polygon;
}

void SGCollisionPolygon2D::update_internal_shape() const {
	Vector<fixed_vector2> points;
	points.resize(fixed_polygon.size());

	for (int i = 0; i < fixed_polygon.size(); i++) {
		Ref<SGFixedVector2> point = fixed_polygon[i];
		if (point.is_valid()) {
			points.write[i] = point->get_internal();
		}
	}

	internal_shape->set_points(points);
}

void SGCollisionPolygon2D::sync_to_physics_engine() const {
    if (!disabled) {
        internal_shape->set_transform(get_fixed_transform_internal());
    }
}

String SGCollisionPolygon2D::get_configuration_warning() const {
	return "";
}

SGCollisionPolygon2D::SGCollisionPolygon2D() {
	aabb = Rect2(-10, -10, 20, 20);
    disabled = false;
    collision_object = nullptr;
	internal_shape = memnew(SGPolygon2DInternal);
}

SGCollisionPolygon2D::~SGCollisionPolygon2D() {
    if (collision_object && !disabled) {
        collision_object->remove_shape(internal_shape);
    }
	memdelete(internal_shape);
}
