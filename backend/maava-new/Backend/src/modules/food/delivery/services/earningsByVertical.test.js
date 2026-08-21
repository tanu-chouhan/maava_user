import test from 'node:test';
import assert from 'node:assert/strict';

import { summarizeEarningsByVertical } from './delivery.service.js';

test('splits Food and Mart, and the total is their sum', () => {
    const r = summarizeEarningsByVertical([
        { _id: 'food', earnings: 500, orders: 8 },
        { _id: 'quick', earnings: 300, orders: 5 }
    ]);
    assert.deepEqual(r.byVertical.food, { earnings: 500, orders: 8 });
    assert.deepEqual(r.byVertical.quick, { earnings: 300, orders: 5 });
    assert.equal(r.totalEarnings, 800);
    assert.equal(r.totalOrders, 13);
});

test('pre-merge orders with no vertical count as Food, never dropped', () => {
    // The null bucket is what mongo returns for documents predating the field.
    const r = summarizeEarningsByVertical([
        { _id: 'food', earnings: 100, orders: 2 },
        { _id: null, earnings: 40, orders: 1 },
        { _id: 'weird-value', earnings: 10, orders: 1 }
    ]);
    assert.equal(r.byVertical.food.earnings, 150);
    assert.equal(r.byVertical.food.orders, 4);
    assert.equal(r.byVertical.quick.earnings, 0);
    // The invariant that matters: nothing is lost between parts and total.
    assert.equal(r.totalEarnings, 150);
    assert.equal(r.totalOrders, 4);
});

test('a rider with only Mart trips shows zero under Food', () => {
    const r = summarizeEarningsByVertical([{ _id: 'quick', earnings: 75, orders: 3 }]);
    assert.equal(r.byVertical.food.earnings, 0);
    assert.equal(r.byVertical.food.orders, 0);
    assert.equal(r.totalEarnings, 75);
    assert.equal(r.totalOrders, 3);
});

test('no trips is all zeroes, not NaN', () => {
    for (const empty of [[], null, undefined]) {
        const r = summarizeEarningsByVertical(empty);
        assert.equal(r.totalEarnings, 0);
        assert.equal(r.totalOrders, 0);
    }
});
