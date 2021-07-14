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

#ifndef SG_PHYSICS_2D_INTERNAL_FIXED_VECTOR2_H
#define SG_PHYSICS_2D_INTERNAL_FIXED_VECTOR2_H

#include "fixed.h"

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

};

#endif