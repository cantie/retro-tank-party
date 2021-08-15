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

#ifndef SG_FIXED_MATH_INTERNAL_H
#define SG_FIXED_MATH_INTERNAL_H

#include <core/typedefs.h>
#include <core/math/math_funcs.h>
#include "../thirdparty/libfixmath/fixmath.h"

struct fixed {
    fix16_t value;

    _FORCE_INLINE_ fixed() {}

    explicit _FORCE_INLINE_ fixed(fix16_t p_initial_value)
        : value(p_initial_value) {}

    static _FORCE_INLINE_ fixed from_int(int p_int_value) {
        return fixed(fix16_from_int(p_int_value));
    }
    
    static _FORCE_INLINE_ fixed from_float(float p_float_value) {
        return fixed(fix16_from_float(p_float_value));
    }

    _FORCE_INLINE_ int32_t to_int() const {
        return fix16_to_int(value);
    }

    _FORCE_INLINE_ float to_float() const {
        return fix16_to_float(value);
    }

    _FORCE_INLINE_ fixed operator+(const fixed& p_other) const {
        return fixed(fix16_add(value, p_other.value));
    }

    _FORCE_INLINE_ void operator+=(const fixed& p_other) {
        value = fix16_add(value, p_other.value);
    }

    _FORCE_INLINE_ fixed operator-(const fixed& p_other) const {
        return fixed(fix16_sub(value, p_other.value));
    }

    _FORCE_INLINE_ void operator-=(const fixed& p_other) {
        value -= p_other.value;
    }

    _FORCE_INLINE_ fixed operator*(const fixed& p_other) const {
        // Naive implementation - maybe this is fine?
        /*
        int64_t temp = value * p_other.value;
        return fixed((int32_t)(temp >> FRACTIONAL_BITS));
        */
        return fixed(fix16_mul(value, p_other.value));
    }

    _FORCE_INLINE_ void operator*=(const fixed& p_other) {
        // Naive implementation - maybe this is fine?
        /*
        int64_t temp = value * p_other.value;
        value = (int32_t)(temp >> FRACTIONAL_BITS);
        */
        value = fix16_mul(value, p_other.value);
    }

    _FORCE_INLINE_ fixed operator/(const fixed& p_other) const {
        // Naive implementation - maybe this is fine?
        //return fixed(((int64_t)value << FRACTIONAL_BITS) / (int64_t)p_other.value);
        return fixed(fix16_div(value, p_other.value));
    }

    _FORCE_INLINE_ void operator/=(const fixed& p_other) {
        // Naive implementation - maybe this is fine?
        //value = (int32_t)(((int64_t)value << FRACTIONAL_BITS) / (int64_t)p_other.value);
        value = fix16_div(value, p_other.value);
    }

    _FORCE_INLINE_ bool operator==(const fixed &p_other) const { return value == p_other.value; }
    _FORCE_INLINE_ bool operator!=(const fixed &p_other) const { return value != p_other.value; }
    _FORCE_INLINE_ bool operator<=(const fixed &p_other) const { return value <= p_other.value; }
    _FORCE_INLINE_ bool operator>=(const fixed &p_other) const { return value >= p_other.value; }
    _FORCE_INLINE_ bool operator< (const fixed &p_other) const { return value <  p_other.value; }
    _FORCE_INLINE_ bool operator> (const fixed &p_other) const { return value >  p_other.value; }

    _FORCE_INLINE_ fixed abs() const { return fixed(fix16_abs(value)); }

    _FORCE_INLINE_ fixed  sin() const { return fixed(fix16_sin(value)); }
    _FORCE_INLINE_ fixed  cos() const { return fixed(fix16_cos(value)); }
    _FORCE_INLINE_ fixed  tan() const { return fixed(fix16_tan(value)); }
    _FORCE_INLINE_ fixed asin() const { return fixed(fix16_asin(value)); }
    _FORCE_INLINE_ fixed acos() const { return fixed(fix16_acos(value)); }
    _FORCE_INLINE_ fixed atan() const { return fixed(fix16_atan(value)); }
    _FORCE_INLINE_ fixed atan2(const fixed &inY) const { return fixed(fix16_atan2(value, inY.value)); }
    _FORCE_INLINE_ fixed sqrt() const { return fixed(fix16_sqrt(value)); }
};

struct fixed_vector2 {
    enum Axis {
        AXIS_X,
        AXIS_Y,
    };

    union {
        fixed x;
        fixed width;
    };
    union {
        fixed y;
        fixed height;
    };

	_FORCE_INLINE_ fixed_vector2(fixed p_x, fixed p_y) 
        : x(p_x), y(p_y) {}
	_FORCE_INLINE_ fixed_vector2()
        : x(fixed(0)), y(fixed(0)) {}

	_FORCE_INLINE_ fixed &operator[](int p_idx) {
		return p_idx ? y : x;
	}
	_FORCE_INLINE_ const fixed &operator[](int p_idx) const {
		return p_idx ? y : x;
    }

	_FORCE_INLINE_ fixed_vector2 operator+(const fixed_vector2 &p_v) const {
        return fixed_vector2(x + p_v.x, y + p_v.y);
    }
	_FORCE_INLINE_ void operator+=(const fixed_vector2 &p_v) {
        x += p_v.x;
        y += p_v.y;
    }
	_FORCE_INLINE_ fixed_vector2 operator-(const fixed_vector2 &p_v) const {
        return fixed_vector2(x - p_v.x, y - p_v.y);
    }
	_FORCE_INLINE_ void operator-=(const fixed_vector2 &p_v) {
        x -= p_v.x;
        y -= p_v.y;
    }
	_FORCE_INLINE_ fixed_vector2 operator*(const fixed_vector2 &p_v) const {
        return fixed_vector2(x * p_v.x, y * p_v.y);
    }
	_FORCE_INLINE_ void operator*=(const fixed_vector2 &p_v) {
        x *= p_v.x;
        y *= p_v.y;
    }
	_FORCE_INLINE_ fixed_vector2 operator/(const fixed_vector2 &p_v) const {
        return fixed_vector2(x / p_v.x, y / p_v.y);
    }
	_FORCE_INLINE_ void operator/=(const fixed_vector2 &p_v) {
        x /= p_v.x;
        y /= p_v.y;
    }

	_FORCE_INLINE_ fixed_vector2 operator+(const fixed &p_v) const {
        return fixed_vector2(x + p_v, y + p_v);
    }
	_FORCE_INLINE_ void operator+=(const fixed &p_v) {
        x += p_v;
        y += p_v;
    }
	_FORCE_INLINE_ fixed_vector2 operator-(const fixed &p_v) const {
        return fixed_vector2(x - p_v, y - p_v);
    }
	_FORCE_INLINE_ void operator-=(const fixed &p_v) {
        x -= p_v;
        y -= p_v;
    }
	_FORCE_INLINE_ fixed_vector2 operator*(const fixed &p_v) const {
        return fixed_vector2(x * p_v, y * p_v);
    }
	_FORCE_INLINE_ void operator*=(const fixed &p_v) {
        x *= p_v;
        y *= p_v;
    }
	_FORCE_INLINE_ fixed_vector2 operator/(const fixed &p_v) const {
        return fixed_vector2(x / p_v, y / p_v);
    }
	_FORCE_INLINE_ void operator/=(const fixed &p_v) {
        x /= p_v;
        y /= p_v;
    }

    _FORCE_INLINE_ fixed_vector2 abs() const {
        return fixed_vector2(x.abs(), y.abs());
    }

};

struct fixed_rect2 {
    fixed_vector2 position;
    fixed_vector2 size;

    _FORCE_INLINE_ fixed_rect2(fixed_vector2 p_position, fixed_vector2 p_size) 
        : position(p_position), size(p_size) {}

    _FORCE_INLINE_ fixed_vector2 get_min() const {
        return position - size;
    }

    _FORCE_INLINE_ fixed_vector2 get_max() const {
        return position + size;
    }

};

struct fixed_transform2d {
    fixed_vector2 elements[3];


};

#endif