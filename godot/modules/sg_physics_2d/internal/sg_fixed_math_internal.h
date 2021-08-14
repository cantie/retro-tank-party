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

struct fixed {
    int32_t value;

    static const uint16_t FRACTIONAL_BITS = 10;
    static const uint16_t FRACTIONAL_SIZE = 1024;

    _FORCE_INLINE_ fixed() {}

    explicit _FORCE_INLINE_ fixed(int32_t p_initial_value)
        : value(p_initial_value) {}

    static _FORCE_INLINE_ fixed from_int(int p_int_value) {
        return fixed(p_int_value << FRACTIONAL_BITS);
    }
    
    static _FORCE_INLINE_ fixed from_float(float p_float_value) {
        return fixed(p_float_value * FRACTIONAL_SIZE);
    }

    _FORCE_INLINE_ int32_t to_int() const {
        return value >> FRACTIONAL_BITS;
    }

    _FORCE_INLINE_ float to_float() const {
        return (float)value / FRACTIONAL_SIZE;
    }

    _FORCE_INLINE_ fixed operator+(const fixed& p_other) const {
        return fixed(value + p_other.value);
    }

    _FORCE_INLINE_ void operator+=(const fixed& p_other) {
        value += p_other.value;
    }

    _FORCE_INLINE_ fixed operator-(const fixed& p_other) const {
        return fixed(value - p_other.value);
    }

    _FORCE_INLINE_ void operator-=(const fixed& p_other) {
        value -= p_other.value;
    }

    _FORCE_INLINE_ fixed operator*(const fixed& p_other) const {
        int64_t temp = value * p_other.value;
        return fixed((int32_t)(temp >> FRACTIONAL_BITS));
    }

    _FORCE_INLINE_ void operator*=(const fixed& p_other) {
        int64_t temp = value * p_other.value;
        value = (int32_t)(temp >> FRACTIONAL_BITS);
    }

    _FORCE_INLINE_ fixed operator/(const fixed& p_other) const {
        return fixed(((int64_t)value << FRACTIONAL_BITS) / (int64_t)p_other.value);
    }

    _FORCE_INLINE_ void operator/=(const fixed& p_other) {
        value = (int32_t)(((int64_t)value << FRACTIONAL_BITS) / (int64_t)p_other.value);
    }

    _FORCE_INLINE_ bool operator<=(const fixed &p_other) const {
        return value <= p_other.value;
    }

    _FORCE_INLINE_ fixed abs() const {
        return fixed(Math::abs(value));
    }

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

#endif