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

#include "sg_fixed_vector2.h"

void SGFixedVector2::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_x"), &SGFixedVector2::get_x);
    ClassDB::bind_method(D_METHOD("set_x", "x"), &SGFixedVector2::set_x);
    ClassDB::bind_method(D_METHOD("get_y"), &SGFixedVector2::get_y);
    ClassDB::bind_method(D_METHOD("set_y", "y"), &SGFixedVector2::set_y);

	ADD_PROPERTY(PropertyInfo(Variant::INT, "x", PROPERTY_HINT_NONE), "set_x", "get_x");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "y", PROPERTY_HINT_NONE), "set_y", "get_y");

    ClassDB::bind_method(D_METHOD("add", "other_vector"), &SGFixedVector2::add);
    ClassDB::bind_method(D_METHOD("iadd", "other_vector"), &SGFixedVector2::iadd);
    ClassDB::bind_method(D_METHOD("sub", "other_vector"), &SGFixedVector2::sub);
    ClassDB::bind_method(D_METHOD("isub", "other_vector"), &SGFixedVector2::isub);
    ClassDB::bind_method(D_METHOD("mul", "other_vector"), &SGFixedVector2::mul);
    ClassDB::bind_method(D_METHOD("imul", "other_vector"), &SGFixedVector2::imul);
    ClassDB::bind_method(D_METHOD("div", "other_vector"), &SGFixedVector2::div);
    ClassDB::bind_method(D_METHOD("idiv", "other_vector"), &SGFixedVector2::idiv);

    ClassDB::bind_method(D_METHOD("addf", "fixed_value"), &SGFixedVector2::addf);
    ClassDB::bind_method(D_METHOD("iaddf" "fixed_value"), &SGFixedVector2::iaddf);
    ClassDB::bind_method(D_METHOD("subf", "fixed_value"), &SGFixedVector2::subf);
    ClassDB::bind_method(D_METHOD("isubf", "fixed_value"), &SGFixedVector2::isubf);
    ClassDB::bind_method(D_METHOD("mulf", "fixed_value"), &SGFixedVector2::mulf);
    ClassDB::bind_method(D_METHOD("imulf", "fixed_value"), &SGFixedVector2::imulf);
    ClassDB::bind_method(D_METHOD("divf", "fixed_value"), &SGFixedVector2::divf);
    ClassDB::bind_method(D_METHOD("idivf", "fixed_value"), &SGFixedVector2::idivf);

    ClassDB::bind_method(D_METHOD("from_float", "float_vector"), &SGFixedVector2::from_float);
    ClassDB::bind_method(D_METHOD("to_float"), &SGFixedVector2::to_float);

	ADD_SIGNAL(MethodInfo("changed"));
}

Ref<SGFixedVector2> SGFixedVector2::add(const Ref<SGFixedVector2>& p_other) const {
    return Ref<SGFixedVector2>(memnew(SGFixedVector2(value + p_other->value)));
}

void SGFixedVector2::iadd(const Ref<SGFixedVector2>& p_other) {
    value += p_other->value;
    emit_signal("changed");
}

Ref<SGFixedVector2> SGFixedVector2::sub(const Ref<SGFixedVector2>& p_other) const {
    return Ref<SGFixedVector2>(memnew(SGFixedVector2(value - p_other->value)));
}

void SGFixedVector2::isub(const Ref<SGFixedVector2>& p_other) {
    value -= p_other->value;
    emit_signal("changed");
}

Ref<SGFixedVector2> SGFixedVector2::mul(const Ref<SGFixedVector2>& p_other) const {
    return Ref<SGFixedVector2>(memnew(SGFixedVector2(value * p_other->value)));
}

void SGFixedVector2::imul(const Ref<SGFixedVector2>& p_other) {
    value *= p_other->value;
    emit_signal("changed");
}

Ref<SGFixedVector2> SGFixedVector2::div(const Ref<SGFixedVector2>& p_other) const {
    return Ref<SGFixedVector2>(memnew(SGFixedVector2(value / p_other->value)));
}

void SGFixedVector2::idiv(const Ref<SGFixedVector2>& p_other) {
    value /= p_other->value;
    emit_signal("changed");
}

Ref<SGFixedVector2> SGFixedVector2::addf(int p_other) const {
    return Ref<SGFixedVector2>(memnew(SGFixedVector2(value + fixed(p_other))));
}

void SGFixedVector2::iaddf(int p_other) {
    value += fixed(p_other);
    emit_signal("changed");
}

Ref<SGFixedVector2> SGFixedVector2::subf(int p_other) const {
    return Ref<SGFixedVector2>(memnew(SGFixedVector2(value - fixed(p_other))));
}

void SGFixedVector2::isubf(int p_other) {
    value -= fixed(p_other);
    emit_signal("changed");
}

Ref<SGFixedVector2> SGFixedVector2::mulf(int p_other) const {
    return Ref<SGFixedVector2>(memnew(SGFixedVector2(value * fixed(p_other))));
}

void SGFixedVector2::imulf(int p_other) {
    value *= fixed(p_other);
    emit_signal("changed");
}

Ref<SGFixedVector2> SGFixedVector2::divf(int p_other) const {
    return Ref<SGFixedVector2>(memnew(SGFixedVector2(value / fixed(p_other))));
}

void SGFixedVector2::idivf(int p_other) {
    value /= fixed(p_other);
    emit_signal("changed");
}

void SGFixedVector2::from_float(Vector2 p_float_vector) {
    value.x = fixed::from_float(p_float_vector.x);
    value.y = fixed::from_float(p_float_vector.y);
    emit_signal("changed");
}

Vector2 SGFixedVector2::to_float() const {
    return Vector2(value.x.to_float(), value.y.to_float());
}
