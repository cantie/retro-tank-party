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
#include <core/error_macros.h>

int64_t sg_sqrt_64(int64_t num);

struct fixed {
    int64_t value;

    _FORCE_INLINE_ fixed() {}

    explicit _FORCE_INLINE_ fixed(int64_t p_initial_value)
        : value(p_initial_value) {}

    static const fixed ZERO;
    static const fixed ONE;
    static const fixed HALF;
    static const fixed TWO;
    static const fixed NEG_ONE;
    static const fixed PI;
    static const fixed TAU;
    static const fixed PI_DIV_4;
    static const fixed EPSILON;

    static _FORCE_INLINE_ fixed from_int(int64_t p_int_value) {
        return fixed(p_int_value << 16);
    }
    
    static _FORCE_INLINE_ fixed from_float(float p_float_value) {
        return fixed(p_float_value * 65536);
    }

    static _FORCE_INLINE_ bool is_equal_approx(fixed a, fixed b) {
        if (a == b) {
            return true;
        }
        fixed tolerance = fixed::EPSILON * a.abs();
        if (tolerance < fixed::EPSILON) {
            tolerance = fixed::EPSILON;
        }
        return (a - b).abs() < tolerance;
    }

    static _FORCE_INLINE_ bool is_equal_approx(fixed a, fixed b, fixed tolerance) {
        if (a == b) {
            return true;
        }
        return (a - b).abs() < tolerance;
    }

    _FORCE_INLINE_ int64_t to_int() const {
        return value >> 16;
    }

    _FORCE_INLINE_ float to_float() const {
        return (float)value / 65536;
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
        return fixed((value * p_other.value) >> 16);
    }

    _FORCE_INLINE_ void operator*=(const fixed& p_other) {
        value = (value * p_other.value) >> 16;
    }

    _FORCE_INLINE_ fixed operator/(const fixed& p_other) const {
        return fixed((value << 16) / p_other.value);
    }

    _FORCE_INLINE_ void operator/=(const fixed& p_other) {
        value = (value << 16) / p_other.value;
    }

    _FORCE_INLINE_ bool operator==(const fixed &p_other) const { return value == p_other.value; }
    _FORCE_INLINE_ bool operator!=(const fixed &p_other) const { return value != p_other.value; }
    _FORCE_INLINE_ bool operator<=(const fixed &p_other) const { return value <= p_other.value; }
    _FORCE_INLINE_ bool operator>=(const fixed &p_other) const { return value >= p_other.value; }
    _FORCE_INLINE_ bool operator< (const fixed &p_other) const { return value <  p_other.value; }
    _FORCE_INLINE_ bool operator> (const fixed &p_other) const { return value >  p_other.value; }

    _FORCE_INLINE_ fixed abs() const { return (value < 0) ? fixed(-value) : *this; }
    _FORCE_INLINE_ fixed operator-() const { return fixed(-value); }
    _FORCE_INLINE_ fixed sqrt() const { return fixed(sg_sqrt_64(value)); }

    fixed  sin() const;
    fixed  cos() const;
    fixed  tan() const;
    fixed asin() const;
    fixed acos() const;
    fixed atan() const;
    fixed atan2(const fixed &inY) const;
};

#define FIXED_SGN(m_v) (((m_v) < fixed(0)) ? fixed::NEG_ONE : fixed::ONE)

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

    static const fixed FIXED_UNIT_EPSILON;
    static const fixed_vector2 ZERO;

	_FORCE_INLINE_ fixed_vector2(fixed p_x, fixed p_y) 
        : x(p_x), y(p_y) {}
	_FORCE_INLINE_ fixed_vector2()
        : x(fixed::ZERO), y(fixed::ZERO) {}
    
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

    bool operator==(const fixed_vector2 &p_v) const;
    bool operator!=(const fixed_vector2 &p_v) const;

	fixed angle() const;

	void set_rotation(fixed p_radians) {
		x = p_radians.cos();
		y = p_radians.sin();
	}

    _FORCE_INLINE_ fixed_vector2 abs() const {
        return fixed_vector2(x.abs(), y.abs());
    }
    _FORCE_INLINE_ fixed_vector2 operator-() const {
        return fixed_vector2(-x, -y);
    }

    fixed_vector2 rotated(fixed p_rotation) const;

    void normalize();
    fixed_vector2 normalized() const;
    bool is_normalized() const;

    fixed length() const;
    fixed length_squared() const;
    int64_t length_squared_64() const;

    fixed dot(const fixed_vector2 &p_other) const;
    int64_t dot_64(const fixed_vector2 &p_other) const;
    fixed cross(const fixed_vector2 &p_other) const;

    _FORCE_INLINE_ static fixed_vector2 linear_interpolate(const fixed_vector2 &p_a, const fixed_vector2 &p_b, fixed p_weight);

    fixed_vector2 slide(const fixed_vector2 &p_normal) const;
    fixed_vector2 bounce(const fixed_vector2 &p_normal) const;
    fixed_vector2 reflect(const fixed_vector2 &p_normal) const;

    bool is_equal_approx(const fixed_vector2 &p_v) const;
};

fixed_vector2 fixed_vector2::linear_interpolate(const fixed_vector2 &p_a, const fixed_vector2 &p_b, fixed p_weight) {
    fixed_vector2 res = p_a;
    res.x += (p_weight * (p_b.x - p_a.x));
    res.y += (p_weight * (p_b.y - p_a.y));
    return res;
}

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

    _FORCE_INLINE_ fixed tdotx(const fixed_vector2 &v) const { return elements[0][0] * v.x + elements[1][0] * v.y; }
    _FORCE_INLINE_ fixed tdoty(const fixed_vector2 &v) const { return elements[0][1] * v.x + elements[1][1] * v.y; }

    const fixed_vector2 &operator[](int p_idx) const { return elements[p_idx]; }
    fixed_vector2 &operator[](int p_idx) { return elements[p_idx]; }

    _FORCE_INLINE_ fixed_vector2 get_axis(int p_axis) const {
        ERR_FAIL_INDEX_V(p_axis, 3, fixed_vector2());
        return elements[p_axis];
    }
    _FORCE_INLINE_ void set_axis(int p_axis, const fixed_vector2 &p_vec) {
        ERR_FAIL_INDEX(p_axis, 3);
        elements[p_axis] = p_vec;
    }

    void invert();
    fixed_transform2d inverse() const;

    void affine_invert();
    fixed_transform2d affine_inverse() const;

    void set_rotation(fixed p_rot);
    fixed get_rotation() const;
    _FORCE_INLINE_ void set_rotation_and_scale(fixed p_rot, const fixed_vector2 &p_scale);
    void rotate(fixed p_phi);

    void scale(const fixed_vector2 &p_scale);
    void scale_basis(const fixed_vector2 &p_scale);
    void translate(fixed p_tx, fixed p_ty);
    void translate(const fixed_vector2 &p_translation);

    fixed basis_determinant() const;

    fixed_vector2 get_scale() const;
    void set_scale(const fixed_vector2 &p_scale);

    _FORCE_INLINE_ const fixed_vector2 &get_origin() const { return elements[2]; }
    _FORCE_INLINE_ void set_origin(const fixed_vector2 &p_origin) { elements[2] = p_origin; }

    fixed_transform2d scaled(const fixed_vector2 &p_scale) const;
    fixed_transform2d basis_scaled(const fixed_vector2 &p_scale) const;
    fixed_transform2d translated(const fixed_vector2 &p_offset) const;
    fixed_transform2d rotated(fixed p_phi) const;

    fixed_transform2d untranslated() const;

    void orthonormalize();
    fixed_transform2d orthonormalized() const;
    bool is_equal_approx(const fixed_transform2d &p_transform) const;

    bool operator==(const fixed_transform2d &p_transform) const;
    bool operator!=(const fixed_transform2d &p_transform) const;

    void operator*=(const fixed_transform2d &p_transform);
    fixed_transform2d operator*(const fixed_transform2d &p_transform) const;

    fixed_transform2d interpolate_with(const fixed_transform2d &p_transform, fixed p_c) const;

    _FORCE_INLINE_ fixed_vector2 basis_xform(const fixed_vector2 &p_vec) const;
    _FORCE_INLINE_ fixed_vector2 basis_xform_inv(const fixed_vector2 &p_vec) const;
    _FORCE_INLINE_ fixed_vector2 xform(const fixed_vector2 &p_vec) const;
    _FORCE_INLINE_ fixed_vector2 xform_inv(const fixed_vector2 &p_vec) const;
    //_FORCE_INLINE_ fixed_rect2 xform(const fixed_rect2 &p_rect) const;
    //_FORCE_INLINE_ fixed_rect2 xform_inv(const fixed_rect2 &p_rect) const;

    fixed_transform2d(fixed xx, fixed xy, fixed yx, fixed yy, fixed ox, fixed oy) {
        elements[0][0] = xx;
        elements[0][1] = xy;
        elements[1][0] = yx;
        elements[1][1] = yy;
        elements[2][0] = ox;
        elements[2][1] = oy;
    }

    fixed_transform2d(fixed p_rot, const fixed_vector2 &p_pos);
    fixed_transform2d() {
        elements[0][0] = fixed::ONE;
        elements[1][1] = fixed::ONE;
    }
    /*
    fixed_transform2d(const fixed_transform2d& p_other) {
        memcpy(&elements, &p_other.elements, sizeof(elements));
    }
    */
};

fixed_vector2 fixed_transform2d::basis_xform(const fixed_vector2 &p_vec) const {
    return fixed_vector2(tdotx(p_vec), tdoty(p_vec));
}

fixed_vector2 fixed_transform2d::basis_xform_inv(const fixed_vector2 &p_vec) const {
    return fixed_vector2(elements[0].dot(p_vec), elements[1].dot(p_vec));
}

fixed_vector2 fixed_transform2d::xform(const fixed_vector2 &p_vec) const {
    return fixed_vector2(tdotx(p_vec), tdoty(p_vec)) + elements[2];
}

fixed_vector2 fixed_transform2d::xform_inv(const fixed_vector2 &p_vec) const {
    fixed_vector2 v = p_vec - elements[2];
    return fixed_vector2(elements[0].dot(v), elements[2].dot(v));
}

void fixed_transform2d::set_rotation_and_scale(fixed p_rot, const fixed_vector2 &p_scale) {
    elements[0][0] = p_rot.cos() * p_scale.x;
    elements[1][1] = p_rot.cos() * p_scale.y;
    elements[1][0] = -p_rot.sin() * p_scale.y;
    elements[0][1] = p_rot.sin() * p_scale.x;
}

#endif