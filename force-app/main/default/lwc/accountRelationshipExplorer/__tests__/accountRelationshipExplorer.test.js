import { aggregateCounts, connectedNodeIds, filterNodes, isEmptyGraph, labelLines, tooltipText } from 'c/relationshipGraphUtils';

describe('relationship graph data transformations', () => {
    const graphData = { contactCount: 1, opportunityCount: 1, caseCount: 0, nodes: [
        { id: '001', type: 'Account', label: 'Acme', isCentral: true },
        { id: '003', type: 'Contact', label: 'Ada Lovelace', subtitle: 'Architect', isCentral: false },
        { id: '006', type: 'Opportunity', label: 'Renewal', subtitle: 'Prospecting', isCentral: false }
    ], links: [] };
    it('shows an empty graph until relationships are supplied', () => {
        expect(isEmptyGraph(undefined, new Set(['Contact']), '')).toBe(true);
        expect(isEmptyGraph(graphData, new Set(), '')).toBe(true);
    });
    it('filters nodes by active type and search text', () => {
        expect(filterNodes(graphData, new Set(['Contact', 'Opportunity']), 'ada')).toHaveLength(2);
        expect(filterNodes(graphData, new Set(['Contact']), '')).toHaveLength(2);
        expect(filterNodes(graphData, new Set(['Opportunity']), '')).toHaveLength(2);
    });
    it('keeps progressively expanded secondary nodes visible independently of first-level filters', () => {
        const expandedData = { ...graphData, nodes: [...graphData.nodes, { id: '00T', type: 'Task', label: 'Follow up', isCentral: false }] };
        expect(filterNodes(expandedData, new Set(), '')).toEqual(expect.arrayContaining([expect.objectContaining({ type: 'Task' })]));
    });
    it('reports aggregate counts from the server response', () => {
        expect(aggregateCounts({ contactCount: 3, opportunityCount: 2, caseCount: 1 })).toEqual({ contacts: 3, opportunities: 2, cases: 1 });
    });
    it('identifies only the selected node and direct connections for focus styling', () => {
        const connected = connectedNodeIds([{ source: '001', target: '003' }, { source: '001', target: '006' }], '003');
        expect([...connected]).toEqual(expect.arrayContaining(['001', '003']));
        expect(connected.has('006')).toBe(false);
    });
    it('keeps meaningful labels readable over two lines and supplies tooltip context', () => {
        expect(labelLines('Alpine Northern Plant Upgrade', 16)).toEqual(['Alpine Northern', 'Plant Upgrade']);
        expect(tooltipText({ type: 'Opportunity', label: 'Renewal', subtitle: 'Prospecting', detailOne: '32000' })).toContain('Renewal');
    });
});
