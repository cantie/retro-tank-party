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

#include "sg_broadphase_2d_internal.h"

void SGBroadphase2DInternal::_add_element_to_cells(Element *p_element) {
	fixed_vector2 min = p_element->bounds.get_min();
	fixed_vector2 max = p_element->bounds.get_max();

	int32_t from_x = min.x.to_int() / cell_size;
	int32_t from_y = min.y.to_int() / cell_size;
	int32_t to_x = max.x.to_int() / cell_size;
	int32_t to_y = max.y.to_int() / cell_size;

	p_element->indices.resize(((to_x + 1) - from_x) * ((to_y + 1) - from_y));
	int index = 0;

	for (int32_t x = from_x; x <= to_x; x++) {
		for (int32_t y = from_y; y <= to_y; y++) {
			HashKey key(x, y);
			Map<HashKey, Cell *>::Element *cell_element = cells.find(key);
			Cell *cell;

			if (cell_element) {
				cell = cell_element->get();
			}
			else {
				cell = memnew(Cell);
				cell_element = cells.insert(key, cell);
			}

			cell->elements.push_back(p_element);
			p_element->indices.write[index++] = key;
		}
	}
}

void SGBroadphase2DInternal::_remove_element_from_cells(Element *p_element) {
	for (int i = 0; i < p_element->indices.size(); i++) {
		HashKey key = p_element->indices[i];
		Map<HashKey, Cell *>::Element *cell_element = cells.find(key);

		if (!cell_element) {
			continue;
		}

		Cell *cell = cell_element->get();
		cell->elements.erase(p_element);

		if (cell->elements.size() == 0) {
			cells.erase(key);
		}
	}
	p_element->indices.clear();
}

void SGBroadphase2DInternal::_clear_cells() {
	for (Map<HashKey, Cell *>::Element *E = cells.front(); E; E = E->next()) {
		memdelete(E->get());
	}
	cells.clear();
}

SGBroadphase2DInternal::Element *SGBroadphase2DInternal::create_element(SGCollisionObject2DInternal *p_object) {
	Element *element = memnew(Element);
	elements.push_back(element);

	element->object = p_object;
	element->bounds = p_object->get_bounds();
	_add_element_to_cells(element);

	return element;
}

void SGBroadphase2DInternal::update_element(Element *p_element) {
	_remove_element_from_cells(p_element);
	_add_element_to_cells(p_element);
}

void SGBroadphase2DInternal::delete_element(Element *p_element) {
	_remove_element_from_cells(p_element);
	elements.erase(p_element);
	memdelete(p_element);
}

Set<SGCollisionObject2DInternal *> *SGBroadphase2DInternal::find_nearby(const fixed_rect2 &p_bounds) const {
	Set<SGCollisionObject2DInternal *> *results = memnew(Set<SGCollisionObject2DInternal *>);

	fixed_vector2 min = p_bounds.get_min();
	fixed_vector2 max = p_bounds.get_max();

	int32_t from_x = min.x.to_int() / cell_size;
	int32_t from_y = min.y.to_int() / cell_size;
	int32_t to_x = max.x.to_int() / cell_size;
	int32_t to_y = max.y.to_int() / cell_size;

	for (int32_t x = from_x; x <= to_x; x++) {
		for (int32_t y = from_y; y <= to_y; y++) {
			HashKey key(x, y);
			const Map<HashKey, Cell *>::Element *cell_element = cells.find(key);
			Cell *cell;

			if (!cell_element) {
				continue;
			}

			cell = cell_element->get();
			for (List<Element *>::Element *E = cell->elements.front(); E; E = E->next()) {
				results->insert(E->get()->object);
			}
		}
	}

	return results;
}

void SGBroadphase2DInternal::set_cell_size(int p_cell_size) {
	if (cell_size != p_cell_size) {
		cell_size = p_cell_size;

		_clear_cells();
		for (List<Element *>::Element *E = elements.front(); E; E = E->next()) {
			Element *element = E->get();
			element->indices.clear();
			_add_element_to_cells(element);
		}
	}
}

SGBroadphase2DInternal::SGBroadphase2DInternal(int p_cell_size) {
	cell_size = p_cell_size;
}

SGBroadphase2DInternal::~SGBroadphase2DInternal() {
	_clear_cells();
	for (List<Element *>::Element *E = elements.front(); E; E = E->next()) {
		memdelete(E->get());
	}
}
