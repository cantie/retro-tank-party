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

#include "fixed_vector2.h"

void FixedVector2::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_x"), &FixedVector2::get_x);
    ClassDB::bind_method(D_METHOD("set_x"), &FixedVector2::set_x);
    ClassDB::bind_method(D_METHOD("get_y"), &FixedVector2::get_y);
    ClassDB::bind_method(D_METHOD("set_y"), &FixedVector2::set_y);

	ADD_PROPERTY(PropertyInfo(Variant::INT, "x", PROPERTY_HINT_NONE), "set_x", "get_x");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "y", PROPERTY_HINT_NONE), "set_y", "get_y");

    ClassDB::bind_method(D_METHOD("add"), &FixedVector2::add);
    ClassDB::bind_method(D_METHOD("iadd"), &FixedVector2::iadd);
    ClassDB::bind_method(D_METHOD("sub"), &FixedVector2::sub);
    ClassDB::bind_method(D_METHOD("isub"), &FixedVector2::isub);

    ClassDB::bind_method(D_METHOD("to_float"), &FixedVector2::to_float);
}

Ref<FixedVector2> FixedVector2::add(const Ref<FixedVector2>& p_other) const {
    return Ref<FixedVector2>(memnew(FixedVector2(value + p_other->value)));
}

void FixedVector2::iadd(const Ref<FixedVector2>& p_other) {
    value += p_other->value;
}

Ref<FixedVector2> FixedVector2::sub(const Ref<FixedVector2>& p_other) const {
    return Ref<FixedVector2>(memnew(FixedVector2(value - p_other->value)));
}

void FixedVector2::isub(const Ref<FixedVector2>& p_other) {
    value -= p_other->value;
}

Vector2 FixedVector2::to_float() const {
    return Vector2(value.x.to_float(), value.y.to_float());
}