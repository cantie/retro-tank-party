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

#include "sg_fixed_math_internal.h"

const fixed fixed::ZERO = fixed(0);
const fixed fixed::ONE  = fixed(fix16_one);
const fixed fixed::NEG_ONE  = fixed(-fix16_one);
const fixed fixed::EPSILON = fixed(fix16_eps);

// Tolerate more precision error than normal.
const fixed fixed_vector2::FIXED_UNIT_EPSILON = fixed(65);

bool fixed_vector2::operator==(const fixed_vector2 &p_v) const {
    return x == p_v.x && y == p_v.y;
}

bool fixed_vector2::operator!=(const fixed_vector2 &p_v) const {
    return x != p_v.x || y != p_v.y;
}

fixed fixed_vector2::angle() const {
    return y.atan2(x);
}

fixed_vector2 fixed_vector2::rotated(fixed p_rotation) const {
	fixed_vector2 v;
	v.set_rotation(angle() + p_rotation);
	v *= length();
	return v;
}

void fixed_vector2::normalize() {
    fixed l = x * x + y * y;
    if (l != fixed::ZERO) {
        l = l.sqrt();
        x /= l;
        y /= l;
    }
}

fixed_vector2 fixed_vector2::normalized() const {
    fixed_vector2 v = *this;
    v.normalize();
    return v;
}

bool fixed_vector2::is_normalized() const {
    return fixed::is_equal_approx(length_squared(), fixed::ONE, fixed_vector2::FIXED_UNIT_EPSILON);
}

fixed fixed_vector2::length() const {
    return (x * x + y * y).sqrt();
}

fixed fixed_vector2::length_squared() const {
    return x * x + y * y;
}

fixed fixed_vector2::dot(const fixed_vector2 &p_other) const {
    return x * p_other.x + y * p_other.y;
}

fixed fixed_vector2::cross(const fixed_vector2 &p_other) const {
    return x * p_other.y - y * p_other.x;
}

bool fixed_vector2::is_equal_approx(const fixed_vector2 &p_v) const {
    return fixed::is_equal_approx(x, p_v.x) && fixed::is_equal_approx(y, p_v.y);
}

void fixed_transform2d::invert() {
    SWAP(elements[0][1], elements[1][0]);
    elements[2] = basis_xform(-elements[2]);
}

fixed_transform2d fixed_transform2d::inverse() const {
    fixed_transform2d inv = *this;
    inv.invert();
    return inv;
}

void fixed_transform2d::affine_invert() {
    fixed det = basis_determinant();
#ifdef MATH_CHECKS
    ERR_FAIL_COND(det == 0);
#endif
    fixed idet = fixed::ONE / det;

    SWAP(elements[0][0], elements[1][1]);
    elements[0] *= fixed_vector2(idet, -idet);
    elements[1] *= fixed_vector2(-idet, idet);

    elements[2] = basis_xform(-elements[2]);
}

fixed_transform2d fixed_transform2d::affine_inverse() const {
    fixed_transform2d inv = *this;
    inv.affine_invert();
    return inv;
}

void fixed_transform2d::rotate(fixed p_phi) {
    *this = fixed_transform2d(p_phi, fixed_vector2()) * (*this);
}

fixed fixed_transform2d::get_rotation() const {
    return elements[0].y.atan2(elements[0].x);
}

void fixed_transform2d::set_rotation(fixed p_rot) {
    fixed_vector2 scale = get_scale();
    fixed cr = p_rot.cos();
    fixed sr = p_rot.sin();
    elements[0][0] = cr;
    elements[0][1] = sr;
    elements[1][0] = -sr;
    elements[1][1] = cr;
    set_scale(scale);
}

fixed_transform2d::fixed_transform2d(fixed p_rot, const fixed_vector2 &p_pos) {
    fixed cr = p_rot.cos();
    fixed sr = p_rot.sin();
    elements[0][0] = cr;
    elements[0][1] = sr;
    elements[1][0] = -sr;
    elements[1][1] = cr;
    elements[2] = p_pos;
}

fixed_vector2 fixed_transform2d::get_scale() const {
    fixed det_sign = FIXED_SGN(basis_determinant());
    return fixed_vector2(elements[0].length(), det_sign * elements[1].length());
}

void fixed_transform2d::set_scale(const fixed_vector2 &p_scale) {
    elements[0].normalize();
    elements[1].normalize();
    elements[0] *= p_scale.x;
    elements[1] *= p_scale.y;
}

void fixed_transform2d::scale(const fixed_vector2 &p_scale) {
    scale_basis(p_scale);
    elements[2] *= p_scale;
}

void fixed_transform2d::scale_basis(const fixed_vector2 &p_scale) {
    elements[0][0] *= p_scale.x;
    elements[0][1] *= p_scale.y;
    elements[1][0] *= p_scale.x;
    elements[1][1] *= p_scale.y;
}

void fixed_transform2d::translate(fixed p_tx, fixed p_ty) {
    translate(fixed_vector2(p_tx, p_ty));
}

void fixed_transform2d::translate(const fixed_vector2 &p_translation) {
    elements[2] += basis_xform(p_translation);
}

void fixed_transform2d::orthonormalize() {
    fixed_vector2 x = elements[0];
    fixed_vector2 y = elements[1];

    x.normalized();
    y = (y - x * (x.dot(y)));
    y.normalize();

    elements[0] = x;
    elements[1] = y;
}

fixed_transform2d fixed_transform2d::orthonormalized() const {
    fixed_transform2d t = *this;
    t.orthonormalize();
    return t;
}

bool fixed_transform2d::is_equal_approx(const fixed_transform2d &p_transform) const {
    return elements[0].is_equal_approx(p_transform.elements[0]) && elements[1].is_equal_approx(p_transform.elements[1]) && elements[2].is_equal_approx(p_transform.elements[2]);
}

bool fixed_transform2d::operator==(const fixed_transform2d &p_transform) const {
    for (int i = 0; i < 3; i++) {
        if (elements[i] != p_transform.elements[i]) {
            return false;
        }
    }
    return true;
}

bool fixed_transform2d::operator!=(const fixed_transform2d &p_transform) const {
    for (int i = 0; i < 3; i++) {
        if (elements[i] != p_transform.elements[i]) {
            return true;
        }
    }
    return false;
}

void fixed_transform2d::operator*=(const fixed_transform2d &p_transform) {
    elements[2] = xform(p_transform.elements[2]);

    fixed x0, x1, y0, y1;

    x0 = tdotx(p_transform.elements[0]);
    x1 = tdoty(p_transform.elements[0]);
    y0 = tdotx(p_transform.elements[1]);
    y1 = tdoty(p_transform.elements[1]);

    elements[0][0] = x0;
    elements[0][1] = x1;
    elements[1][0] = y0;
    elements[1][1] = y1;
}

fixed_transform2d fixed_transform2d::operator*(const fixed_transform2d &p_transform) const {
    fixed_transform2d t = *this;
    t *= p_transform;
    return t;
}

fixed_transform2d fixed_transform2d::scaled(const fixed_vector2 &p_scale) const {
    fixed_transform2d t = *this;
    t.scale(p_scale);
    return t;
}

fixed_transform2d fixed_transform2d::basis_scaled(const fixed_vector2 &p_scale) const {
    fixed_transform2d t = *this;
    t.scale_basis(p_scale);
    return t;
}

fixed_transform2d fixed_transform2d::translated(const fixed_vector2 &p_offset) const {
    fixed_transform2d t = *this;
    t.translate(p_offset);
    return t;
}

fixed_transform2d fixed_transform2d::rotated(fixed p_phi) const {
    fixed_transform2d t = *this;
    t.rotate(p_phi);
    return t;
}

fixed fixed_transform2d::basis_determinant() const {
    return elements[0].x * elements[1].y - elements[0].y * elements[1].x;
}

fixed_transform2d fixed_transform2d::interpolate_with(const fixed_transform2d &p_transform, fixed p_c) const {
    fixed_vector2 p1 = get_origin();
    fixed_vector2 p2 = p_transform.get_origin();

    fixed r1 = get_rotation();
    fixed r2 = p_transform.get_rotation();

    fixed_vector2 s1 = get_scale();
    fixed_vector2 s2 = p_transform.get_scale();

    fixed_vector2 v1(r1.cos(), r1.sin());
    fixed_vector2 v2(r2.cos(), r2.sin());

    fixed dot = v1.dot(v2);
    dot = CLAMP(dot, fixed::NEG_ONE, fixed::ONE);

    fixed_vector2 v;

    // 65500 = ~0.9995
    if (dot > fixed(65500)) {
        v = fixed_vector2::linear_interpolate(v1, v2, p_c).normalized();
    }
    else {
        fixed angle = p_c * dot.acos();
        fixed_vector2 v3 = (v2 - v1 * dot).normalized();
        v = v1 * angle.cos() + v3 * angle.sin();
    }

    fixed_transform2d res(v.y.atan2(v.x), fixed_vector2::linear_interpolate(p1, p2, p_c));
    res.scale_basis(fixed_vector2::linear_interpolate(s1, s2, p_c));
    return res;
}
