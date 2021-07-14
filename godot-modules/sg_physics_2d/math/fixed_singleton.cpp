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

#include "fixed_singleton.h"

#include "./internal/fixed.h"

Fixed *Fixed::singleton = NULL;

Fixed::Fixed() {
    ERR_FAIL_COND(singleton != NULL);
    singleton = this;
}

Fixed::~Fixed() {
    singleton = NULL;
}

Fixed *Fixed::get_singleton() {
    return singleton;
}

void Fixed::_bind_methods() {
    ClassDB::bind_method(D_METHOD("from_int"), &Fixed::from_int);
    ClassDB::bind_method(D_METHOD("from_float"), &Fixed::from_float);
    ClassDB::bind_method(D_METHOD("to_int"), &Fixed::to_int);
    ClassDB::bind_method(D_METHOD("to_float"), &Fixed::to_float);
    ClassDB::bind_method(D_METHOD("mul"), &Fixed::mul);
    ClassDB::bind_method(D_METHOD("div"), &Fixed::div);
    ClassDB::bind_method(D_METHOD("vector2"), &Fixed::vector2);
}

int Fixed::from_int(int p_int_value) const {
    return fixed::from_int(p_int_value).value;
}

int Fixed::from_float(float p_float_value) const {
    return fixed::from_float(p_float_value).value;
}

int Fixed::to_int(int p_fixed_value) const {
    return fixed(p_fixed_value).to_int();
}

float Fixed::to_float(int p_fixed_value) const {
    return fixed(p_fixed_value).to_float();
}

int Fixed::mul(int p_fixed_one, int p_fixed_two) const {
    return (fixed(p_fixed_one) * fixed(p_fixed_two)).value;
}

int Fixed::div(int p_fixed_one, int p_fixed_two) const {
    return (fixed(p_fixed_one) / fixed(p_fixed_two)).value;
}

Ref<FixedVector2> Fixed::vector2(int p_fixed_x, int p_fixed_y) const {
    return Ref<FixedVector2>(memnew(FixedVector2(fixed_vector2(fixed(p_fixed_x), fixed(p_fixed_y)))));
}