import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { LimiHistory } from '../data/model/LimiHistory';

const DB_NAME: string = 'limi_room.db';
const TABLE_NAME: string = 'limi_history';

const CREATE_TABLE_SQL: string =
  `CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (` +
  'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'originUrl TEXT NOT NULL, ' +
  'processedUrl TEXT NOT NULL, ' +
  'datetime TEXT NOT NULL)';

export class HistoryDB {
  private static rdbStore: relationalStore.RdbStore | null = null;
  private static dataChangedCallback: (() => void) | null = null;

  static setDataChangedCallback(callback: (() => void) | null): void {
    HistoryDB.dataChangedCallback = callback;
  }

  private static notifyDataChanged(): void {
    if (HistoryDB.dataChangedCallback !== null) {
      HistoryDB.dataChangedCallback();
    }
  }

  static async init(context: common.Context): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1,
    };
    HistoryDB.rdbStore = await relationalStore.getRdbStore(context, config);
    await HistoryDB.rdbStore.executeSql(CREATE_TABLE_SQL);
  }

  static async insert(item: LimiHistory): Promise<number> {
    if (HistoryDB.rdbStore === null) {
      return -1;
    }
    const valueBucket: Record<string, relationalStore.ValueType> = {
      'originUrl': item.originUrl,
      'processedUrl': item.processedUrl,
      'datetime': item.datetime,
    };
    const result = await HistoryDB.rdbStore.insert(TABLE_NAME, valueBucket);
    HistoryDB.notifyDataChanged();
    return result;
  }

  static async getAllSortedByDatetimeDesc(): Promise<LimiHistory[]> {
    if (HistoryDB.rdbStore === null) {
      return [];
    }
    const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.orderByDesc('datetime');
    const resultSet = await HistoryDB.rdbStore.query(predicates);
    const list: LimiHistory[] = [];
    if (resultSet !== null) {
      while (resultSet.goToNextRow()) {
        const h = new LimiHistory();
        h.id = resultSet.getLong(resultSet.getColumnIndex('id'));
        h.originUrl = resultSet.getString(resultSet.getColumnIndex('originUrl'));
        h.processedUrl = resultSet.getString(resultSet.getColumnIndex('processedUrl'));
        h.datetime = resultSet.getString(resultSet.getColumnIndex('datetime'));
        list.push(h);
      }
      resultSet.close();
    }
    return list;
  }

  static async deleteById(id: number): Promise<number> {
    if (HistoryDB.rdbStore === null) {
      return 0;
    }
    const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.equalTo('id', id);
    const result = await HistoryDB.rdbStore.delete(predicates);
    HistoryDB.notifyDataChanged();
    return result;
  }
}
